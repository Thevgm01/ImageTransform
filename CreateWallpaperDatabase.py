import os
import sys

filename = "wallpapers.txt"
filedir = os.path.dirname(sys.argv[0])
filepath = os.path.join(filedir, filename)
wallpaperDir = sys.argv[1]
wallpaperDirLen = len(wallpaperDir) + 1

print("Collecting wallpapers in " + wallpaperDir)

file = open(filepath,"w+")
file.write("          \n") # Reserve space for writing the total number of wallpapers at the beginning
file.write(wallpaperDir + os.path.sep + "\n") # Write the root path

count = 0
for root, dirs, files in os.walk(wallpaperDir, followlinks=True):
    for name in files:
        if root.endswith("thumbnails"):
            continue
        if name.endswith(".jpg") or name.endswith(".png") or name.endswith(".jpeg"):
            file.write(os.path.join(root[wallpaperDirLen:], name) + "\n")
            count += 1

file.seek(0)
file.write(str(count))
file.close()
print("Wrote " + str(count + 3) + " lines to " + filename)
#os.system("start " + wallpaperDatabase)
