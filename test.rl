print("break example")
x is 1
while true
    inc x
    if (x = 10) break end
end
print(x)
print("skip example")
for x of 1 to 20
    if (x % 2 != 0) skip end
    if (x = 20) break end
    print(x)
end