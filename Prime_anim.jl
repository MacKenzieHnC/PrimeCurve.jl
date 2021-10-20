using GLMakie
using Makie.Colors

# Change these
Δθ = 1//16 # Must be rational. Multiplied by π later to avoid floating point errors
max_prime = 500 # List will choose all numbers less than or equal to this
framerate = 60
speed_multiplier = 50//1 # Must be Rational. Multiplier to change dot speed
total_time = 180 # seconds
set_theme!(theme_black())
resolution = (1920, 1080)
tail_length = 1000
show_dots = false

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
y_height = ceil(1.05 * primes_list[end])
x_width = ceil(y_height * resolution[1] // resolution[2])
speed_multiplier *= (framerate//60)
Δθ /= denominator(speed_multiplier)

# Function to get next frame
function step_data!(points, current_step, cycle, top_half, Δθ, scale)
    current_step += 1
    progress = current_step * Δθ
    if progress >= 1
        push!(points, (2*scale*(cycle+1), 0))
        current_step -= 1//Δθ
        top_half = !top_half
        cycle += 1
    end

    if current_step != 0
        if top_half
            θ = π*(1 - progress)
        else
            θ = π*(1 + progress)
        end
        push!(points, (2*scale*cycle + scale*(cos(θ)+1), scale*sin(θ)))
    end

    return current_step, cycle, top_half
end

function filter_points(list, tail_length)

    num_to_remove = 0
    if length(list) > tail_length
        num_to_remove = length(list) - tail_length
    end

    counter = 1
    x_lim = x_center[] - (3*x_width/4)
    while list[counter][1] < x_lim
        num_to_remove += 1
        counter +=1
    end

    if num_to_remove > 0
        list = list[1+num_to_remove:end]
    end

    return num_to_remove
end

#######################################################################
#   ANIMATION
#######################################################################
begin
    x_center = Node(0//1)
    tick_step = ceil(x_width / 4.4)

    # Make scene
    fig = Figure(resolution = resolution)
    ax = fig[1,1] = Axis(fig,
                        xticks = MultiplesTicks(4, tick_step, string(" * ", tick_step)),
                        yticks = LinearTicks(4))

    ax.autolimitaspect = 1

    # Add scroll
    on(x_center) do x_center
        # Screen limits
        screen_begin = x_center[] - 2*x_width/3
        limits!(ax, screen_begin, screen_begin + x_width, -y_height/2, y_height/2)
    end
    notify(x_center) # Manually do first update

    # Add time
    timestamps = range(0, total_time, step=1/framerate)

    # Initialize lists
    points, current_step, cycle, top_half = Node[], [], [], []
    for p in primes_list
        push!(points, Point2[(0.0,0.0)])
        append!(current_step, [0//1])
        append!(cycle, [0])
        append!(top_half, [true])
    end

    # Add lines
    for i in 1:length(points)
        lines!(ax, points[i])
    end
    scat_points = Node([a[end] for a in [b[] for b in points]])
    if show_dots
        scatter!(scat_points)
    end

    # Record it
    record(fig, "append_animation.mp4", timestamps;
            framerate = framerate) do frame
        for i in 1:length(points)
            for j in 1:numerator(speed_multiplier)
                current_step[i], cycle[i], top_half[i] = step_data!(points[i][], current_step[i], cycle[i], top_half[i], Δθ//primes_list[i], primes_list[i]/2)
            end

            num_to_remove = filter_points(points[i][], tail_length)
            if num_to_remove > 0
                deleteat!(points[i][], 1:num_to_remove)
            end
            notify(points[i]) # Force notify update
        end

        # Draw dots
        if show_dots
            scat_points[] = [a[end] for a in [b[] for b in points]]
        end
        x_center[] += Δθ * numerator(speed_multiplier)
    end
end
