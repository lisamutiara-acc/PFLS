any_fasta_file=$1

    echo "FASTA File Statistics:"
    echo "----------------------"
    num_seq=$(grep -c ">" $any_fasta_file)  # Count the number of sequences in the FASTA file
    echo "Number of sequences: $num_seq"
    tot_num_seq=$(grep -v "^>" $any_fasta_file | wc -c) # Calculate the total length of all sequences
    echo "Total length of sequences: $tot_num_seq"
    long_seq=$((awk '/^>/{if(seqlen){print seqlen};seqlen=0;next}{seqlen=seqlen+length($0)}END{print seqlen}' $any_fasta_file) | sort -rn | head -1) # Calculate the length of each sequence
    echo "Length of the longest sequence: $long_seq"
    short_seq=$((awk '/^>/{if(seqlen){print seqlen};seqlen=0;next}{seqlen=seqlen+length($0)}END{print seqlen}' $any_fasta_file) | sort -rn | tail -1) # Calculate the length of each sequence
    echo "Length of the shortest sequence: $short_seq"
    avg_seq=$(( $tot_num_seq / $num_seq ))
    echo "Average sequence length: $avg_seq"
    tot_gc=$(awk '!/^>/{n=n+gsub(/[GC]/, "")}END{print n}' $any_fasta_file) # Calculate the total number of G and C bases
    percent_gc=$(( $tot_gc * 100 / $tot_num_seq )) # Calculate the percentage of G and C bases
    echo "GC Content (%): $percent_gc%"