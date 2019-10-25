using Random
using DataFrames
using CSV

mutable struct Player
  decklist
  deck
  life
  hand
  discardpile
  trigrams
end

function cast(spell::AbstractString, user::Player, opponent::Player)
    #println(string("CASTING ", spell))
    if spell == "S_F"
        opponent.life -= 3
    elseif spell == "S_H"
        drawcard(user)
        drawcard(user)
    else
        println(string("ERROR: UNKNOWN SPELL ", spell))
    end
end

function popfirsttrigram(p::Player)
    for i in 1:length(p.hand)
        if startswith(p.hand[i], "T_")
            c = p.hand[i]
            deleteat!(p.hand, i)
            return c
        end
    end
    return nothing
end

function drawcard(p::Player)
    if length(p.deck) > 0
        push!(p.hand, pop!(p.deck))
    end
end

function canplayspell(p::Player, s::AbstractString)
    #get element of spell, assume third char
    element = s[3]
    requiredtrigram = string("T_", element)
    #if player has correct trigram, we're good
    return in(requiredtrigram, p.trigrams)
end


function taketurn(p::Player, opponent::Player)
    #draw a card
    drawcard(p)
    #println(string("Player hand: ", p.hand))
    #play one trigram
    t = popfirsttrigram(p)
    if t != nothing
        #println("Plays a trigram")
        push!(p.trigrams, t)
    end
    #println(string("Player trigrams: ", p.trigrams))
    #calculate mana
    mana = length(p.trigrams)

    #play as many spells as possible
    stopcasting = false
    while stopcasting == false
        for i = 1:length(p.hand)
            card = p.hand[i]
            #if we've casted all the spells we can, our turn is done
            if mana < 1
                stopcasting = true
                break
            end
            #make sure we're actually looking at a spell
            if startswith(card, "S_")
                #see if we have the right trigram to play it
                if canplayspell(p, p.hand[i])
                    #cast it!
                    deleteat!(p.hand, i)
                    cast(card, p, opponent)
                    mana -= 1
                    #decrement index so we don't skip any cards
                    break
                end
            end
        end
        #if we checked every card, we're done
        stopcasting = true
    end
end

function newplayer(decklist)
    return Player(decklist, copy(decklist), 20, [], [], [])
end

function randomdeck()
    d = []
    for _ = 1:40
        push!(d, rand(("T_F", "S_F", "T_H", "S_H")))
    end
    return d
end

function wincon(p1::Player, p2::Player)
    if p1.life < 1
        return 2
    end
    if p2.life < 1
        return 1
    end
    if length(p1.deck) == 0
        return 2
    end
    if length(p2.deck) == 0
        return 1
    end
    #return 0 if no one has won yet
    return 0
end

function playround(p1::Player, p2::Player)
    #shuffle decks
    shuffle!(p1.deck)
    shuffle!(p2.deck)
    #Draw hands
    for _ = 1:7
        drawcard(p1)
        drawcard(p2)
    end
    gameover = false
    while gameover == false
        #p1 turn
        #println("Player 1 turn! (", p1.life, ")")
        taketurn(p1, p2)
        w = wincon(p1, p2)
        if w != 0
            return w
        end
        #println("Player 2 turn! (", p2.life, ")")
        taketurn(p2, p1)
        w = wincon(p1, p2)
        if w != 0
            return w
        end
    end
end

#Do trials!
function trials(deck1, deck2, n)
    println(string("Deck 1: ", sort(deck1)))
    println(string("Deck 2: ", sort(deck2)))
    wins1 = 0
    wins2 = 0
    for i = 1:n
        #new round
        a = newplayer(deck1)
        b = newplayer(deck2)
        result = playround(a, b)
        if result == 1
            wins1 += 1
        elseif result == 2
            wins2 += 1
        end
    end
    println(string("Deck 1 wins: ", wins1))
    println(string("Deck 2 wins: ", wins2))
    return (wins1, wins2)
end

#init
d1 = randomdeck()
d2 = randomdeck()

#exports
results = trials(d1, d2, 100)
df = DataFrame(A = sort(d1), B = sort(d2), C = results[1], D = results[2])
CSV.write("output.csv", df)
println("Output file created.")
