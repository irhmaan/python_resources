
# *args is a tuple, immutable, ordered and allows dups
def add(*args):
    print(args)
    return sum(args)

print(add(1, 2, 3, 4, 5,5))



# **args is dict, unique keys, dup values, mutable

def test(**kargs):
    for key, value in kargs.items():
        print(key, value)


test(tag="machine_name", p_1="Param 1", p2="Param 2")
