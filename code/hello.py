import sys, repeat

def main():
    print("hi, there", sys.argv[1])
    #* sys.argv contains the args passed , 0 is for prg name & can be ignored.

    print(repeat.repeat("Hey", True))
    print(repeat.repeat("Hi", False))


#* standard code to call main() function to begin

if __name__ == "__main__":
    main()