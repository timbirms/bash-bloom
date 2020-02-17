# BASH-BLOOM

Between the two abberations contained in this repo, you get about 1100 lines of 
inpenetrable bash supported by my otherwise unrelated 1100 line _shared.bash_ lib.

### _bloom-files_
The slightly sane example, _bloom-files_ is something for you distributed file-system 
ops people to figure out since you it manages at least the A in ACID :) by filling 
file-system 'slack space' with symlinks and subdirectories that can encode huge numbers.

_bloom-files_ is also fun to read since it uses _four_ concurrent bash pipes to pump data.


### _bloom-images_
This slightly crazy example lets you watch a bloom filter fill up using an image viewer
instead of file-system tools. It can do monochrome and color compressed into png's so that
you could give an image like this someone so that your system would remember what they know
when they upload the image again. Neato! :)


![bloom-filter-viz](bloom-500-4.4.8-256w29.png "bloom-filter-viz")   ![bloom-filter-viz](bloom-500-5.5.10-1024w539.png "bloom-filter-viz")


### Inside
Created in Emacs using Outshine, then exported from a literate org-mode file.
Uses openssl hmac mode for hashes, imagemagic for the pngs,
Optionally feh, ristretto and jumpapp for visualization.

### Note
Please scan the code ahead of time and fill-in the _path_ near the top of these scripts.
You want output to go to ram or another temp-storage or things could get crowded.

### Good Luck! 
Send feedback if you survive your encounter with this code!
