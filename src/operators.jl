import Base: +, -, *, &, |, xor, ==

for op in (:+, :-, :&, :|, :xor, :(==))
    @eval begin
        function ($op)(a::Cenum{T}, b::Cenum{S}) where {T<:Integer,S<:Integer}
            N = promote_type(T, S)
            ($op)(N(a), N(b))
        end
        function ($op)(a::Cenum{T}, b::S) where {T<:Integer,S<:Integer}
            N = promote_type(T, S)
            ($op)(N(a), N(b))
        end
        ($op)(a::S, b::Cenum{T}) where {T<:Integer,S<:Integer} = ($op)(b, a)
    end
end

Base.convert(::Type{T1}, x::Cenum{T2}) where {T1<:Integer,T2<:Integer} = convert(T1, T2(x))

(::Type{T})(x) where {T<:Cenum} = convert(T, x)
