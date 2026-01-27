#!/bin/bash

start=0
end=30
step=5
angles=($(seq $start $step $end))

baseCase="baseCase"
rm -rf AoA_*

# Crear archivo resumen con encabezado completo
echo "AoA,Cl,Cd,cm_x0.00,cm_x0.16,cm_x0.32,cm_x0.48,cm_x0.64,cm_x0.80,cm_x0.96,cm_x1.12,cm_x1.28,cm_x1.44,cm_x1.60" > polar.csv

for angle in "${angles[@]}"; do
    caseDir="AoA_${angle}"
    echo "🔄 Corriendo simulación para AoA = ${angle}°..."

    # Copiar caso base
    cp -r "$baseCase" "$caseDir" || { echo "❌ No se pudo copiar baseCase"; exit 1; }

    # Convertir ángulo a radianes
    radians=$(echo "$angle * 3.14159265359 / 180" | bc -l)

    # Calcular componentes Ux y Uy (manteniendo magnitud constante de 18 m/s)
    Ux=$(echo "scale=6; 18 * c($radians)" | bc -l)
    Uy=$(echo "scale=6; 18 * s($radians)" | bc -l)

    # Modificar archivo U
    sed -i "s/internalField.*/internalField   uniform (${Ux} ${Uy} 0);/" "$caseDir/0/U"

    # Para cada ángulo, calcular las direcciones correctas
    liftX=$(echo "scale=6; -s($radians)" | bc -l)  # -sin(α)
    liftY=$(echo "scale=6;  c($radians)" | bc -l)  #  cos(α)
    dragX=$(echo "scale=6;  c($radians)" | bc -l)  #  cos(α)  
    dragY=$(echo "scale=6;  s($radians)" | bc -l)  #  sin(α)

    # Actualizar forceCoeffs para todos los canards
    for i in {1..11}; do
        sed -i "/canard_${i}/,/^}$/ s/liftDir.*/    liftDir         (${liftX} ${liftY} 0);/" "$caseDir/system/forceCoeffs"
        sed -i "/canard_${i}/,/^}$/ s/dragDir.*/    dragDir         (${dragX} ${dragY} 0);/" "$caseDir/system/forceCoeffs"
    done

    # Correr simulación
    cd "$caseDir"

    # Descomponer el dominio para correr en paralelo
    decomposePar

    # Ejecutar la simulación usando 3 núcleos
    mpirun -np 3 simpleFoam -parallel > log.simpleFoam

    # Reconstruir el dominio después de la simulación
    reconstructPar

    cd ..

    # Arrays para almacenar todos los valores
    declare -a cm_values
    Cl="NaN"
    Cd="NaN"

    # Buscar archivos de coeficientes para cada canard
    for i in {1..11}; do
        coeffsFile=$(find "$caseDir/postProcessing/canard_${i}/" -name "forceCoeffs.dat" | head -n 1)
        
        if [[ -f "$coeffsFile" ]]; then
            # Extraer última línea útil (ignorar encabezado)
            lastLine=$(tail -n +10 "$coeffsFile" | tail -n 1)
            
            # Extraer columna Cm (columna 2)
            Cm=$(echo "$lastLine" | awk '{print $2}')
            cm_values+=("$Cm")
            
            # Para Cl y Cd, usar los valores del primer canard
            if [ $i -eq 1 ]; then
                Cd=$(echo "$lastLine" | awk '{print $3}')
                Cl=$(echo "$lastLine" | awk '{print $4}')
            fi
        else
            echo "⚠️  No se encontró archivo de resultados para canard_${i}"
            cm_values+=("NaN")
        fi
    done

    # Construir línea completa para el CSV
    csv_line="$angle,$Cl,$Cd"
    for cm_val in "${cm_values[@]}"; do
        csv_line="$csv_line,$cm_val"
    done
    
    echo "$csv_line" >> polar.csv
    echo "✅ AoA ${angle}° → Cl = $Cl, Cd = $Cd, Cm guardados para todas las posiciones"

    # Limpiar array para próxima iteración
    unset cm_values
done

echo "🎉 Simulación completa!"
echo "📄 Resultados guardados en polar.csv con formato:"
echo "   AoA,Cl,Cd,cm_x0.00,cm_x0.16,cm_x0.32,cm_x0.48,cm_x0.64,cm_x0.80,cm_x0.96,cm_x1.12,cm_x1.28,cm_x1.44,cm_x1.60"