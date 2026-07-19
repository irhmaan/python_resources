dict = {}

dict['a'] = 'alpha'
dict['b'] = 'beta'
dict['g'] = 'gamma'

print(dict)

for key in dict:
    print(key, dict[key])

print('keys:' , dict.keys())
print('values:' , dict.values())


for key in sorted(dict.keys()):
    print('Values:' , dict[key])

print('items:' , dict.items())


for k , v in dict.items(): print( k ,'>', v)




########### testing with lists.

l = [1,23,4,5,6]
print(l[-1])

