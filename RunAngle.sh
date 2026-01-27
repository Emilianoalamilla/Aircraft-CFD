#!/bin/bash

start=0
end=30
step=5
angles=($(seq $start $step $end))

baseCase="baseCase"
rm -rf AoA_*

# Crear archivo resumen con encabezado
echo "AoA,Cl,Cd,cm" > polar.csv

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

    # Actualizar forceCoeffs
    sed -i "s/liftDir.*/liftDir         (${liftX} ${liftY} 0);/" "$caseDir/system/forceCoeffs"
    sed -i "s/dragDir.*/dragDir         (${dragX} ${dragY} 0);/" "$caseDir/system/forceCoeffs"


    #Modificar forceCoeffs
    #sed -i "s/liftDir.*/liftDir         (${liftY} ${liftX} 0);/" "$caseDir/system/forceCoeffs"
    #sed -i "s/dragDir.*/dragDir         (${liftX} ${liftY} 0);/" "$caseDir/system/forceCoeffs"

    
    # Correr simulación
cd "$caseDir"

# Descomponer el dominio para correr en paralelo
decomposePar

# Ejecutar la simulación usando 3 núcleos
mpirun -np 3 simpleFoam -parallel > log.simpleFoam

# Reconstruir el dominio después de la simulación
reconstructPar

cd ..


    # Buscar archivo de coeficientes (con o sin extensión)
    coeffsFile=$(find "$caseDir/postProcessing/" -name "forceCoeffs.dat" | head -n 1)


    if [[ -f "$coeffsFile" ]]; then
        # Extraer última línea útil (ignorar encabezado)
        lastLine=$(tail -n +10 "$coeffsFile" | tail -n 1)

        # Extraer columnas (Cm, Cd, Cl, ...)
        Cm=$(echo "$lastLine" | awk '{print $2}')
        Cd=$(echo "$lastLine" | awk '{print $3}')
        Cl=$(echo "$lastLine" | awk '{print $4}')

        echo "✅ AoA ${angle}° → Cl = $Cl, Cd = $Cd"

        # Guardar en CSV
        echo "$angle,$Cl,$Cd,$Cm" >> polar.csv
    else
        echo "⚠️  No se encontró archivo de resultados en $caseDir/postProcessing/forceCoeffs/"
    fi
done
