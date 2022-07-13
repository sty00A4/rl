use std.os
os.exec("echo Hello from os.exec")
print("the time is " + (os.time() as String))
os.exit()
print("this message won't appear")