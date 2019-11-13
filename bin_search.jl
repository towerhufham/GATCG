function binarysearch(list, element)
    first = 0
    last = length(list)
    while first <= last
        mid = (first + last) ÷ 2
        if list[mid] == element
            return mid
        else
            if element < list[mid]
                last = mid - 1
            else
                first = mid + 1
            end
        end
    end
    return false
end

println(binarysearch([2, 4, 6, 7, 8, 11, 15, 26, 57], 6))
