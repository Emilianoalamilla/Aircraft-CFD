import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import tkinter as tk
from matplotlib import font_manager

def load_data(csv_file):
    """Cargar datos del archivo CSV"""
    try:
        df = pd.read_csv(csv_file)
        return df
    except FileNotFoundError:
        print(f"Error: No se encontró el archivo {csv_file}")
        return None
    except Exception as e:
        print(f"Error al cargar el archivo: {e}")
        return None

def get_screen_dimensions():
    """Obtener dimensiones de la pantalla"""
    root = tk.Tk()
    screen_width = root.winfo_screenwidth()
    screen_height = root.winfo_screenheight()
    root.destroy()
    return screen_width, screen_height

def configure_plot_style():
    """Configurar el estilo del gráfico con fuentes disponibles"""
    # Buscar fuentes serif disponibles
    available_fonts = [f.name for f in font_manager.fontManager.ttflist if 'serif' in f.name.lower()]
    
    # Configurar estilo
    plt.style.use('seaborn-white')
    params = {
        'axes.labelsize': 11,
        'axes.titlesize': 12,
        'legend.fontsize': 9,
        'xtick.labelsize': 9,
        'ytick.labelsize': 9,
        'axes.linewidth': 0.8,
        'lines.linewidth': 1.5,
        'grid.alpha': 0.3,
        'figure.dpi': 100,
        'savefig.dpi': 300,
    }
    
    # Usar fuente serif si está disponible
    if available_fonts:
        params['font.family'] = 'serif'
        if 'Times New Roman' in available_fonts:
            params['font.serif'] = 'Times New Roman'
        elif 'Computer Modern Roman' in available_fonts:
            params['font.serif'] = 'Computer Modern Roman'
        else:
            params['font.serif'] = available_fonts[0]
    else:
        print("Advertencia: No se encontraron fuentes serif, usando fuentes por defecto")
    
    plt.rcParams.update(params)

def create_polar_plots(csv_file='polar.csv'):
    """Función principal para crear todas las gráficas en una sola figura"""
    # Configurar estilo
    configure_plot_style()
    
    # Cargar datos
    df = load_data(csv_file)
    if df is None:
        return
    
    print(f"Datos cargados exitosamente. Dimensiones: {df.shape}")
    print(f"Columnas: {list(df.columns)}")
    print(f"Rango de ángulos: {df['AoA'].min()}° a {df['AoA'].max()}°")
    
    # Obtener dimensiones de pantalla y calcular tamaño de figura
    screen_width, screen_height = get_screen_dimensions()
    fig_width = min(10, screen_width / 100)  # 10 pulgadas o el ancho de pantalla/100
    fig_height = min(8, screen_height / 100)  # 8 pulgadas o el alto de pantalla/100
    
    # Crear figura con 4 subplots
    fig, axs = plt.subplots(2, 2, figsize=(fig_width, fig_height))
    fig.suptitle('Análisis de Polar Aerodinámica', y=1.02, fontsize=14, fontweight='bold')
    
    # Convertir datos a arrays NumPy
    aoa = df['AoA'].to_numpy()
    cl = df['Cl'].to_numpy()
    cd = df['Cd'].to_numpy()
    
    # --- Gráfico 1: Ángulo vs Cl ---
    axs[0,0].plot(aoa, cl, 'b-', marker='o', markersize=5, 
                 markerfacecolor='white', markeredgecolor='b', markeredgewidth=1)
    
    # Etiquetas de ángulo
    for i, (angle, cl_val) in enumerate(zip(aoa, cl)):
        if i % 3 == 0:  # Etiquetas cada 3 puntos
            axs[0,0].annotate(f'{angle}°', (angle, cl_val), xytext=(3, 3), 
                            textcoords='offset points', fontsize=8)
    
    axs[0,0].set_xlabel('Ángulo de ataque [°]')
    axs[0,0].set_ylabel('$C_l$')
    axs[0,0].set_title('Coeficiente de sustentación vs ángulo')
    axs[0,0].grid(True, linestyle=':', alpha=0.5)
    axs[0,0].axhline(0, color='k', linestyle='-', linewidth=0.8, alpha=0.5)
    
    # --- Gráfico 2: Ángulo vs Cd ---
    axs[0,1].plot(aoa, cd, 'r-', marker='s', markersize=5,
                 markerfacecolor='white', markeredgecolor='r', markeredgewidth=1)
    
    for i, (angle, cd_val) in enumerate(zip(aoa, cd)):
        if i % 3 == 0:
            axs[0,1].annotate(f'{angle}°', (angle, cd_val), xytext=(3, 3), 
                            textcoords='offset points', fontsize=8)
    
    axs[0,1].set_xlabel('Ángulo de ataque [°]')
    axs[0,1].set_ylabel('$C_d$')
    axs[0,1].set_title('Coeficiente de arrastre vs ángulo')
    axs[0,1].grid(True, linestyle=':', alpha=0.5)
    
    # --- Gráfico 3: Polar Cl vs Cd ---
    axs[1,0].plot(cd, cl, 'k-', marker='^', markersize=5,
                 markerfacecolor='white', markeredgecolor='k', markeredgewidth=1)
    
    for angle, cd_val, cl_val in zip(aoa, cd, cl):
        if angle % 5 == 0:  # Etiquetas cada 5°
            axs[1,0].annotate(f'{angle}°', (cd_val, cl_val), xytext=(3, 3), 
                            textcoords='offset points', fontsize=8)
    
    axs[1,0].set_xlabel('$C_d$')
    axs[1,0].set_ylabel('$C_l$')
    axs[1,0].set_title('Polar aerodinámica')
    axs[1,0].grid(True, linestyle=':', alpha=0.5)
    axs[1,0].axhline(0, color='k', linestyle='-', linewidth=0.8, alpha=0.5)
    axs[1,0].axvline(0, color='k', linestyle='-', linewidth=0.8, alpha=0.5)
    
    # --- Gráfico 4: Curvas de momento ---
    x_positions = [0.00, 0.16, 0.32, 0.48, 0.64, 0.80, 0.96, 1.12, 1.28, 1.44, 1.60]
    colors = plt.cm.viridis(np.linspace(0, 1, len(x_positions)))
    
    for i, (x_pos, color) in enumerate(zip(x_positions, colors)):
        col_name = f'cm_x{x_pos:.2f}'
        if col_name in df.columns:
            cm = df[col_name].to_numpy()
            axs[1,1].plot(aoa, cm, '-', color=color, marker='', 
                         label=f'x/c={x_pos:.2f}', linewidth=1.2)
    
    axs[1,1].set_xlabel('Ángulo de ataque [°]')
    axs[1,1].set_ylabel('$C_m$')
    axs[1,1].set_title('Coeficiente de momento')
    axs[1,1].grid(True, linestyle=':', alpha=0.5)
    axs[1,1].axhline(0, color='k', linestyle='-', linewidth=0.8, alpha=0.5)
    axs[1,1].legend(fontsize=7, ncol=2, framealpha=0.8)
    
    # Ajustar layout sin conflicto
    plt.subplots_adjust(wspace=0.3, hspace=0.4)
    
    # Mostrar y guardar
    plt.show()
    
    save_plots = input("\n¿Deseas guardar las gráficas? (s/n): ").lower() == 's'
    if save_plots:
        fig.savefig('polar_completa.png', dpi=300, bbox_inches='tight')
        print("Gráfica guardada exitosamente como 'polar_completa.png'")

# Ejecutar el programa
if __name__ == "__main__":
    print("Generador de Polares Aerodinámicas")
    print("="*40)
    
    csv_file = input("Ingresa el nombre del archivo CSV (presiona Enter para 'polar.csv'): ").strip()
    if not csv_file:
        csv_file = 'polar.csv'
    
    create_polar_plots(csv_file)