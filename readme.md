# BASH-BLOOM

![bloom-filter-viz](bloom-500-4.4.8-256w29.png "bloom-filter-viz")   ![bloom-filter-viz](bloom-500-5.5.10-1024w539.png "bloom-filter-viz")


These images are actual bloom-filters understood by _bloom-images_ with the help
of openssl and graphviz.

_bloom-files_ is just as crazy with its use of file-system slack space, symlinks
and subdirectories. _bloom-files_ uses _four_ concurrent bash pipes and openssl.


Between these two abberations, you get about 1100 lines of inpenetrable bash
supported by my otherwise unrelated 1100 line _shared.bash_ library.


Please audit the code and adjust any paths I might have missed in preparing this
archive. *Insure* that you set the _path_ in each of the script to ram or another
temp-storage or things will get very crowded.


Send feedback if you survive your encouter with this code!

I wish you a pleasant evening. 
