using OrdinaryDiffEq, DiffEqDevTools, DiffEqProblemLibrary, DiffEqBase, Base.Test

## Setup Tests

prob = prob_ode_linear

probs = Vector{ODEProblem}(2)
probs[1] = prob
probs[2] = prob_ode_2Dlinear

tspan = [0,1]
tspans = Vector{Vector{Int64}}(2)
tspans[1] = tspan; tspans[2] = tspan
abstols = 1./10.^(3:10)
reltols = 1./10.^(3:10)


setups = [Dict(:alg=>RK4());Dict(:alg=>Euler());Dict(:alg=>BS3());
          Dict(:alg=>Midpoint());Dict(:alg=>BS5());Dict(:alg=>DP5())]


t1 = @elapsed sol = solve(prob,RK4(),dt=1/2^(4))
t2 = @elapsed sol2 = solve(prob,setups[1][:alg],dt=1/2^(4))

@test (sol2[end] == sol[end])

## Shootout Tests

println("Shootout Tests")

shoot = Shootout(prob,setups,dt=1/2^(4))

#show(shoot)
#println(shoot)
shoot[end]

set = ShootoutSet(probs,setups;dt=1/2^(4))

#println(set[1])
#println(set[:])
set[end]
set[1][:]

## WorkPrecision Tests
println("WorkPrecision Tests")
wp = WorkPrecision(prob,DP5(),abstols,reltols;name="Dormand-Prince 4/5")

wp[1]
wp[:]
wp[end]
#show(wp)

wp_set = WorkPrecisionSet(prob,abstols,reltols,setups;dt=1/2^4,numruns=2)

wp_set[1]
wp_set[:]
wp_set[end]
#println(wp_set)
#show(wp_set)
@test (minimum(diff(wp_set[2].errors).==0)) # The errors for a fixed timestep method should be constant


# 2D Linear ODE
function f_2dlin(t,u,du)
  for i in 1:length(u)
    du[i] = 1.01*u[i]
  end
end
function (p::typeof(f_2dlin))(::Type{Val{:analytic}},t,u₀)
  u₀*exp(1.01*t)
end
tspan = (0.0,10.0)
prob = ODEProblem(f_2dlin,rand(100,100),tspan)

abstols = 1./10.^(3:7)
reltols = 1./10.^(0:4)

setups = [Dict(:alg=>DP5())
          Dict(:alg=>Tsit5())]
wp = WorkPrecisionSet(prob,abstols,reltols,setups;save_everystep=false)

function lotka(t,u,du)
  du[1] = 1.5 * u[1] - u[1]*u[2]
  du[2] = -3 * u[2] + u[1]*u[2]
end

prob = ODEProblem(lotka,[1.0;1.0],(0.0,10.0))

abstols = 1./10.^(6:9)
reltols = 1./10.^(3:6)
sol = solve(prob,Vern7(),abstol=1/10^14,reltol=1/10^14)
test_sol = TestSolution(sol)

setups = [Dict(:alg=>DP5())
          Dict(:alg=>Tsit5())
          Dict(:alg=>Vern6())
          ]
wp = WorkPrecisionSet(prob,abstols,reltols,setups;appxsol=test_sol,save_everystep=false,numruns=20,maxiters=10000)
