#!/bin/bash

# Configuration
start_pos=0
end_pos=1.6
steps=10
delta=$(echo "scale=2; ($end_pos-$start_pos)/$steps" | bc -l)
output="cm_results_final_working.csv"

# CSV Header
echo -n "Angle" > $output
for pos in $(seq $start_pos $delta $end_pos); do
    printf ",Position %.2f" $pos >> $output
done
echo "" >> $output

# Function to convert scientific notation to decimal
sci_to_dec() {
    echo "$1" | sed 's/[eE]/*10^/g' | bc -l
}

# Processing function
process_case() {
    local case_dir=$1
    local angle=${case_dir#AoA_}
    angle=${angle%/}
    
    echo "🔍 Processing angle: ${angle}°"

    # Find forceCoeffs.dat
    local coeffs_file="${case_dir}postProcessing/canard_1/0/forceCoeffs.dat"
    
    if [[ ! -f "$coeffs_file" ]]; then
        echo "   ❌ forceCoeffs.dat not found"
        echo -n "$angle" >> $output
        for i in $(seq 0 $steps); do
            echo -n ",NA" >> $output
        done
        echo "" >> $output
        return 1
    fi

    echo "   ✅ Found coefficients file: $coeffs_file"
    
    # Extract the Cm value (convert scientific notation properly)
    local last_line=$(grep "^500 " "$coeffs_file" 2>/dev/null || grep -vE '^#|^$' "$coeffs_file" | tail -1)
    local Cm=$(echo "$last_line" | awk '{print $2}')
    
    # Write to CSV
    echo -n "$angle" >> $output
    
    if [[ "$Cm" =~ ^-?[0-9.eE+-]+$ ]]; then
        # Convert scientific notation to decimal for bc
        Cm_dec=$(sci_to_dec "$Cm")
        
        for pos in $(seq $start_pos $delta $end_pos); do
            # Calculate adjusted Cm
            Cm_adj=$(echo "$Cm_dec + (0.25 * $pos)" | bc -l)
            # Format with 6 decimal places
            printf ",%.6f" "$Cm_adj" >> $output
        done
    else
        echo "   ⚠️  Invalid Cm value: '$Cm'"
        for i in $(seq 0 $steps); do
            echo -n ",NA" >> $output
        done
    fi
    
    echo "" >> $output
    echo "   ✅ Processed successfully (Base Cm: $Cm)"
}

# Process all cases
for case_dir in AoA_*/; do
    process_case "$case_dir"
done

echo "🎉 Final results saved to $output"
echo "📊 Sample output:"
head -n 8 $output | column -t -s,