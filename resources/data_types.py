# list 
# Ordered, mutable, index based insertion is O(n), index access at a[0] is O(1).
# it can store multi format data and dynamically sized.
# duplicate data available.

'''
TYPE        ORDERED         MUTABLE         DUPLICATES      SYNTAX
LIST        Yes             Yes             Yes             [t1,t2]
SET         No              Yes             No              {t1,t2}
DICT        Yes(py 3.6)     Yes             key unique      {k1: t1, k2: t2}
TUPLE       Yes             No              Yes             (t1, t1, t2, t3)

'''
l = [1,2,3, 4]
l.append(5)
print(l)

#nested lists

nested_l = [[12,13],2,3]
print('Nested list', nested_l)
print(nested_l[0])
nested_l[0].append(14)
nested_l.remove(3)
print('Removed 3 from nested list', nested_l)

#! set 
#! unordered, and unindexed and  mutable but doesn't allow duplicate data and if data exist it ignores it
s = {1, 3, 4, 5, 6}

s.add(1)
s.remove(1)

print(s)

#! dict 
#! ordered and unique via key. O(1) operation.
# immutable.
d = {1: 'rahul', 2: 'dev', 3: 'tom'}
print(d)
print(d[1])

print ('=======================Tuples ======================')
#! ordered and unchangeable ,  duplicates.
t = ('dev', 'rehman' , 'roy','roy')
# t[0] = 'deb'
print(t[0])
print(t)



