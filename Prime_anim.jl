using GLMakie
using Makie.Colors

# Change these
Δθ = 1//16 # Must be rational. Multiplied by π later to avoid floating point errors
max_prime = 50 # List will choose all numbers less than or equal to this
framerate = 30
speed = 1//2 # Multiplier to change dot speed
total_time = 180 # seconds
set_theme!(theme_black())
resolution = (1920, 1080)

# Don't change these
primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97,
            101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199,
            211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293,
            307, 311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397,
            401, 409, 419, 421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499,
            503, 509, 521, 523, 541, 547, 557, 563, 569, 571, 577, 587, 593, 599,
            601, 607, 613, 617, 619, 631, 641, 643, 647, 653, 659, 661, 673, 677, 683, 691,
            701, 709, 719, 727, 733, 739, 743, 751, 757, 761, 769, 773, 787, 797,
            809, 811, 821, 823, 827, 829, 839, 853, 857, 859, 863, 877, 881, 883, 887,
            907, 911, 919, 929, 937, 941, 947, 953, 967, 971, 977, 983, 991, 997]
primes_list = collect(Iterators.takewhile(<=(max_prime), primes))
y_height = 1.05 * primes_list[end]
x_width = y_height * resolution[1] // resolution[2]

# Function to get next frame
function step_anim(points, step, cycle, top_half, Δθ, scale)
    step += 1
    progress = step * Δθ
    if progress >= 1
        push!(points[], (2*scale*(cycle+1), 0))
        step -= 1//Δθ
        top_half = !top_half
        cycle += 1
    end

    if step != 0
        if top_half
            θ = π*(1 - progress)
        else
            θ = π*(1 + progress)
        end
        push!(points[], (2*scale*cycle + scale*(cos(θ)+1), scale*sin(θ)))
    end

    return points[], step, cycle, top_half
end

# Initialize lists
points, step, cycle, top_half = Node[], [], [], []
for p in primes_list
    push!(points, Point2[(0.0,0.0)])
    append!(step, [0//1])
    append!(cycle, [0])
    append!(top_half, [true])
end

# Make scene
fig = Figure(resolution = (1920, 1080))
ax = fig[1, 1] = Axis(fig)
ax.autolimitaspect = 1
ax.xticks = ([-2000:20:2000...], string.([-2000:20:2000...]))

# Add lines
lines!(ax,points[1], axis = (yticks = LinearTicks(4),))
for i in 2:length(points)
    lines!(points[i])
end
scat_points = Node([a[end] for a in [b[] for b in points]])
scatter!(scat_points)

# Add time
timestamps = range(0, total_time, step=1/framerate)

# Add scroll
x_center = Node(0.0)
limits!(ax, x_center[] - (2*x_width/3), x_center[] + (1*x_width/3), -y_height/2, y_height/2)
on(x_center) do x_center
    limits!(ax, x_center[] - (2*x_width/3), x_center[] + (1*x_width/3), -y_height/2, y_height/2)
end

# Record it
record(fig, "append_animation.mp4", timestamps;
        framerate = framerate) do frame
    for i in 1:length(points)
        points[i][], step[i], cycle[i], top_half[i] = step_anim(points[i], step[i], cycle[i], top_half[i], Δθ//primes_list[i]*speed, primes_list[i]/2)
    end
    scat_points[] = [a[end] for a in [b[] for b in points]]
    x_center[] += Δθ * speed
    points
end
