def repeat(s, exclaim):
    """
    Return string 's' repeated 3 times.
    If exclaim true, then add !.
    """

    result = s + s + s 
    #! note: + operation is slow as it calculates resulting object size each time.
    #! * calculates resulting obj size only once.
    
    if exclaim:
        result += "!!!"
    return result