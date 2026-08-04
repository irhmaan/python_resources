def find_dup(nums: list):
    seen = set()
    dupes= set()

    for v in nums:
        if v in seen:
            dupes.add(v)
        else:
            seen.add(v)

    return list(seen)

print(find_dup([1,2,3,3,4]))