
using Printf
@enum SudokuResult begin
    found
    notfound
    err
end

struct Sudoku
    board::Array{Int64,2}
    data::Array{Int64,3}
    blocks
end

Sudoku() = begin
    board = zeros(Int64,9,9)
    data = Array{Int64,3}(undef,(9,9,9))
    for i in 1:9
        data[:,:,i] .= i
    end
    blocks = map(b-> begin
            c = Int64(floor((b-1) / 3) * 3 + 1)
            r = ((b-1) % 3) * 3 + 1
            view(data, r:r+2, c:c+2, :)
            end, 1:9)
    blocks = reshape(blocks, 3,3)
    Sudoku(board,data,blocks)
end

setSolved(s::Sudoku, row::Int64, column::Int64, value::Int64) = begin
    s.board[row,column] = value
    s.data[row, column, :] .= 0
    s.data[row, :, value] .= 0
    s.data[:, column, value] .= 0
    br = Int64(floor((row-1)/3)+1)
    bc = Int64(floor((column-1)/3)+1)
    s.blocks[br,bc][:,:,value] .= 0
end


readSudoku(fn::String)::Sudoku = open(fn) do fh
    filedata = collect(reshape(vcat(map(ln -> map(n->parse(Int64,n), split(ln, "")), eachline(fh))...), (9,9))')
    display(filedata)
    println("\n")
    s = Sudoku()
    for r in 1:9
        for c in 1:9
            v = filedata[r,c]
            if v != 0
                setSolved(s,r,c,v)
            end
        end
    end
    s
end

checkCells(s::Sudoku) :: SudokuResult = begin
    rval = notfound
    for r in 1:9
        for c in 1:9
            if s.board[r,c] == 0
                vs = filter(v->v!=0, s.data[r,c,:])
                if length(vs) == 0
                    return err
                elseif  length(vs) == 1
                    setSolved(s,r,c,vs[1])
                    rval = found
                end
            end
        end
    end
    rval
end

checkRows(s::Sudoku)::SudokuResult = begin
    rval = notfound
    for r in 1:9
        for v in 1:9
            cs = []
            for c in 1:9
                if s.data[r,c,v] != 0
                    append!(cs,c)
                end
            end
            if length(cs) == 1
                setSolved(s,r,cs[1],v)
                rval = found
            end
        end
    end
    rval
end

checkColumns(s::Sudoku)::SudokuResult = begin
    rval = notfound
    for c in 1:9
        for v in 1:9
            rs = []
            for r in 1:9
                if s.data[r,c,v] != 0
                    append!(rs,r)
                end
            end
            if length(rs) == 1
                setSolved(s,rs[1],c,v)
                rval = found
            end
        end
    end
    rval
end

blockToBoard(rr::Int64,cc::Int64,br::Int64,bc::Int64) = begin
    r= (rr-1)*3+br
    c = (cc-1)*3+bc
    Int64[r,c]
end

checkBlocks(s::Sudoku)::SudokuResult = begin
    rval = notfound
    for r in 1:3
        for c in 1:3
            for v in 1:9
                f = []
                for br in 1:3
                    for bc in 1:3
                        if s.blocks[r,c][br,bc, v] != 0
                            push!(f, blockToBoard(r,c,br,bc))
                        end
                    end
                end
                if length(f) == 1
                    setSolved(s, f[1][1], f[1][2], v)
                    rval = found
                elseif length(f)==2 || length(f)==3
                    rs = map(n->n[1],f)
                    cs = map(n->n[2],f)
                    if all(n->n==rs[1], rs)
                        for i in 1:9
                            if s.data[rs[1], i, v]!=0 && !(i in cs)
                                s.data[rs[1], i, v]=0
                                rval = found
                            end
                        end
                    end
                    if all(n->n==cs[1], cs)
                        for i in 1:9
                            if  s.data[i, cs[1], v] != 0 && !(i in rs)
                                s.data[i, cs[1], v]=0
                                rval = found
                            end
                        end
                    end
                end
            end
        end
    end
    rval
end


trySolve(s::Sudoku)::Union{Sudoku, Nothing} = begin
    while true
        result = (checkCells(s), checkRows(s), checkColumns(s), checkBlocks(s))
        if any(n->n==err, result)
            return nothing
        end
        if !any(n->n==0, s.board)
            return s
        end
        if !any(n->n==found, result)
#             println(s.data[:,:,1])
            for r in 1:9
                for c in 1:9
                    if s.board[r,c] == 0
                        vs = filter(n->n!=0, s.data[r,c,:])
                        for v in vs
                            s1 = deepcopy(s)
                            println("guessing $r, $c, $v")
                            setSolved(s1,r,c,v)
                            s2 = trySolve(s1)
                            if s2 != nothing
                                return s2
                            end
                             println("guess $r, $c, $v failed")
                        end
                        return nothing
                    end
                end
            end
        end

    end
    s
end
usage() = begin
    println("julia Sudoku.jl <filename>\nwhere <filename> is a text file defining a sudoku board")
end
if length(ARGS) == 1
    try
        s = readSudoku(ARGS[1])
        s1 = trySolve(s)
        println()
        display(s1.board)
    catch
        usage()
        exit()
    end
else
    usage()
end
