with open("wallace.txt", 'w') as f:

    f.write("half_adder ha1 (.a(pp[0][2]), .b(pp[1][1]), .sum(i1[0]), .carry(c1[0]));\n")
    f.write("full_adder fa1 (.a(pp[0][3]), .b(pp[1][2]), .cin(pp[2][1]) .sum(i1[1]), .carry(c1[1]));\n")
    f.write("full_adder fa2 (.a(pp[0][4]), .b(pp[1][3]), .cin(pp[2][2]) .sum(i1[2]), .carry(c1[2]));\n")
    f.write("half_adder ha2 (.a(pp[0][5]), .b(pp[1][4]), .sum(i1[3]), .carry(c1[3]));\n")

    fa = 3
    ha = 3
    count = 4
    for i in range(128):
        if i > 5 or i < 126:
                if i <= 64:
                    times = int(i / 3)
                    for j in range(times):
                        f.write(f"full_adder fa{fa} (.a(pp[0][4]), ")
                        f.write(f".b(pp[1][3]), ")
                        f.write(f".cin(pp[2][2]), ")
                        f.write(f".sum(i1[{count}]), .carry(c1[{count}]));\n")
                        fa += 1
                        count += 1
                    if i % 3 == 2:
                        f.write(f"half_adder ha{ha} (.a(pp[0][5]), .b(pp[1][4]), .sum(i1[{count}]), .carry(c1[{count}]));\n")
                        ha += 1
                        count += 1
                else:
                    times = int((128 - i) / 3)
                    for j in range(times):
                        f.write(f"full_adder fa{fa} (.a(pp[0][4]), .b(pp[1][3]), .cin(pp[2][2]) .sum(i1[{count}]), .carry(c1[{count}]));\n")
                        fa += 1
                        count += 1
                    if i % 3 == 2:
                        f.write(f"half_adder ha{ha} (.a(pp[0][5]), .b(pp[1][4]), .sum(i1[{count}]), .carry(c1[{count}]));\n")
                        ha += 1
                        count += 1