def test_recursion(type = "start", num_stages = 1):

    print("type: ", type)

    if num_stages == 1:
        print("endcase")
        return
    

    test_recursion("A", num_stages = num_stages - 1)
    test_recursion("B", num_stages = num_stages - 1)
    test_recursion("C", num_stages = num_stages - 1)


test_recursion(num_stages=4)