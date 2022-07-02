#Renewable supply curve for the entire world under different discount rates
using Plots, CSV, DataFrames
S=CSV.read("supply curve.csv",DataFrame);
SS=Matrix(S);
x=SS[:,5];
y=SS[:,6];
x1=SS[:,7];
y1=SS[:,8];
x2=SS[:,9];
y2=SS[:,10];
x3=SS[:,11];
y3=SS[:,12];

fig=plot(x, y,label = "Country-specific discount rate", leg=:topleft, lw =1,size = (900, 500))
fig=plot!(x3, y3,label = "Half country risk premium", leg=:topleft, lw =1,size = (900, 500))
fig=plot!(x1, y1,label = "Uniform discount rate", leg=:topleft, xlabel = "Renewable energy supply potential [1000TWh]", ylabel = "RLCOE",color="green",lw =1)
fig=plot!(x2, y2,label = "Electricity demand",color="orange",lw =1)
fig=plot!(xlims=(0,500), ylims=(0, 150))
savefig(fig,"Renewable supply for the world.png")
