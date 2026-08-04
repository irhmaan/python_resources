def chekc(s: str) -> bool:
    s = "".join(char.lower() for char in s if char.isalnum())
    return s == s[::-1]

def checktwo(s: str):
    left, right = 0, len(s)-1

    while left < right:
        if s[left].isalnum() != s[right].isalnum():
            return False
        left += 1
        right-=1
    return True

print(chekc('race car'))
print(checktwo('race car'))
