nonlit_joke



nonlit_joke-6sec.py: 6 second trials
nonlit_joke-8sec.py: 8 second trials




$ python nonlit_joke.py -s SUBJ -l LIST -r RUN -c COUNTER

SUBJ = subject id, any
LIST = 1,2
RUN = 1-3
COUNTER = optseq choice, 1-5




OPTSEQ--6sec

./optseq_files-6sec/optseq2 --ntp 240 --tr 2 --tprescan 0 --psdwin 0 8 --ev joke 6 26 --ev nonjoke 6 26 --nsearch 1000 --nkeep 5 --o ./optseq_files-6sec/times



OPTSEQ--8sec

./optseq_files-8sec/optseq2 --ntp 285 --tr 2 --tprescan 0 --psdwin 0 8 --ev joke 8 26 --ev nonjoke 8 26 --nsearch 1000 --nkeep 5 --o ./optseq_files-8sec/times
