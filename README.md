# Aircraft Aerodynamic Analysis (CFD) - ESIME Ticomán
Este proyecto contiene el estudio aerodinámico de un ala de aeronave mediante simulaciones de barrido de ángulos de ataque ($AoA$).

## 🛠️ Herramientas Utilizadas
* **Solver:** OpenFOAM (`simpleFoam`)
* **Mallas:** `snappyHexMesh` para geometrías complejas.
* **Automatización:** Scripts en Bash (`RunAngle.sh`) para ejecución en serie de casos.
* **Análisis de Datos:** Python (`graficadora.py`) para la generación de polares.

## 📈 Resultados
Se analizaron los coeficientes de sustentación ($C_L$), resistencia ($C_D$) y momento ($C_m$) desde 0° hasta 30°.

![Polar Aerodinámica](animaciones/polar_completa.png)

## 🚀 Cómo replicar
1. Clonar el repositorio.
2. Ir a la carpeta del caso deseado (ej: `AoA_10`).
3. Ejecutar `./Allrun` para generar la malla y correr la simulación.
