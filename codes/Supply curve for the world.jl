#Renewable supply curve for the entire world under different discount rates
using Plots, CSV, DataFrames
S=CSV.read("supply curve.csv",DataFrame);
SS=Matrix(S);
x=SS[:,1];
y=SS[:,2];
x1=SS[:,3];
y1=SS[:,4];
x2=SS[:,5];
y2=SS[:,6];
x3=SS[:,7];
y3=SS[:,8];

fig=plot(x, y,label = "Country-specific discount rate", leg=:topleft, lw =1,size = (900, 500))
fig=plot!(x1, y1,label = "Half country risk premium", leg=:topleft, lw =1,size = (900, 500))
fig=plot!(x2, y2,label = "Uniform discount rate", leg=:topleft, xlabel = "Renewable energy supply potential [1000TWh]", ylabel = "RLCOE",color="green",lw =1)
fig=plot!(x3, y3,label = "Electricity demand",color="orange",lw =1)
fig=plot!(xlims=(0,500), ylims=(0, 150))
savefig(fig,"Renewable supply for the world.png")
