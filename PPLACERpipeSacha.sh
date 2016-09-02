# pplacer pipeline adapted by Sacha, May 2016

# A basic pplacer run looks like:
####### pplacer -c my.refpkg aln.fasta ######

# the reference package is made of the input alignment and tree using the taxtastic package
# the alignment fasta contains the reference sequences (used for the reference tree) 
    # aligned with the query fasta obtained using hhmer

# to get started: go to the right directory
cd /Users/sachacoesel/Documents/PPLACER

# remove possible duplicate sequences from alignment (will mess up PPLACER run later on)
# the name of my alignment is "filename". Later will use $1 in shell script
seqmagick convert --deduplicate-sequences filename.aln.fasta filename.aln.dedup.fasta

# remove stop codon * (asterix) from alignment files (is not recognized by PPLACER)
# you can do find-replace in any text editor

# Make a multiple sequence alignment (MSA), and remove unreliable regions. 
# I like to use Guidance2.0 - MAFFT algorithm, takes a bit of time:
# http://guidance.tau.ac.il/ver2/overview.php#InputMSA

# You can also run MAFFT 7.0 locally on computer:
mafft input.txt > output.txt


# you can use prottest to test for best AA substitution model. 
# Pplacer only knows about the GTR, WAG, LG, and JTT models

# WHEN YOU HAVE YOUR ALIGNMENT READY:
# Build tree with FastTree, creating a log file
FastTree -log filename.tree.log filename.aln.dedup.fasta > filename.tree
# Compare this also with RaxML 

# Look at tree using FigTree or archaeopterix (Forester.jar).

# Make reference package
taxit create -l nod -P filename.refpkg --aln-fasta filename.aln.dedup.fasta --tree-stats filename.tree.log --tree-file filename.tree

# Convert alignment format from fasta to stockholm format
seqmagick convert filename.aln.dedup.fasta filename.aln.dedup.sto

#run HMMbuild to get HMM profile
hmmbuild filename.hmm filename.aln.dedup.sto

# Use hmm profile to do an HMM search on the metatranscriptomics file and get output in .sto format
hmmsearch -A filename.query.sto filename.aln.dedup.hmm /Users//path to meta transcriptome file

# Note from manual: The --tblout and --domtblout options save output in simple tabular
# Only keep hits of e-value less than ....
hmmsearch -A filename.query.sto -E 0.001 --tblout filename.query.txt filename.hmm /Users/path to meta transcriptome file

# use hmmalign to align query hits to the reference alignment
hmmalign -o filename.combo.sto --mapali filename.aln.dedup.sto filename.hmm filename.query.sto

## and than now..... run pplacer using refpkg. You can also do without, but have't tested it yet
pplacer -c filename.refpkg filename.combo.sto

# Now run `guppy fat` to make a phyloXML "fat tree" visualization, and run
# archaeopteryx to look at it. Note that `fat` can be run without the reference
# package specification, e.g.:
#
guppy fat filename.combo.jplace
#

# We have a little script function `aptx` to run archaeopteryx from within this
# script (you can also open them directly from the archaeopteryx user interface
# if you prefer).
aptx() {
    java -jar bin/forester.jar -c bin/_aptx_configuration_file $1
}

aptx filename.combo.xml &

# Look at PPLACER demo for more options