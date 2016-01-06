A1 = -eye(Int, 9) # x >= 0
b1 = zeros(Int, 9)
A2 = eye(Int, 9) # x <= 1
b2 = ones(Int, 9)
A3 = zeros(Int, 9, 9)
b3 = 3 * ones(Int, 9)
i = 1
for a = 1:3
  for b = (a+1):3
    for c = 1:3
      for d = (c+1):3
        ac = a + (c-1) * 3
        ad = a + (d-1) * 3
        bc = b + (c-1) * 3
        bd = b + (d-1) * 3
        A3[i, ac] = 1
        A3[i, ad] = 1
        A3[i, bc] = 1
        A3[i, bd] = 1
        i += 1
      end
    end
  end
end
A = [A1; A2; A3]
b = [b1; b2; b3]
ine = InequalityDescription(A, b)
poly = CDDPolyhedra(ine)
ext  = Description{Rational{Int}}(copygenerators(poly))
target = ones(Int, 9) * (3 // 4)
ok = false
for i = 1:size(ext.V, 1)
  # In julia v0.4 [i,:] returns a row matrix and in v0.5 it is
  # a 1D vector hence this transpose trick to support both
  if (ext.V')[:,i]' == target'
    ok = true
  end
end
@test ok == true

cutA = ones(Int, 1, 9)
cutb = 6
Acut = [cutA; A]
bcut = [cutb; b]
inecut = InequalityDescription(Acut, bcut)
(isredundant, certificate) = redundant(inecut, 1)
@test !isredundant
@test Array{Rational{Int}}(certificate) == [1//1; target]
@test IntSet([]) == redundantrows(inecut)
(issredundant, scertificate) = sredundant(inecut, 1)
@test !issredundant
@test Array{Rational{Int}}(scertificate) == [1//1; target]
