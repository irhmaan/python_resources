def two_sum(nums: list, target):
    seen = {} # dict to store visited element combo

    for i, v in enumerate(nums):
        comp = target-v
        if comp in seen:
            return [seen[comp], i]
        seen[v]= i
    return []

print(two_sum([1,2,3,4,5], 7))
