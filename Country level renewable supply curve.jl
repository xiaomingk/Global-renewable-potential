using Plots, CSV, DataFrames
#Function to plot the country supply courve for renewables (wind and solar)
function plotcountry(reg)
S=CSV.read("$(reg)_VRE.csv",DataFrame);
SS=Matrix(S);
x=SS[:,1];
y=SS[:,2];
fn=plot(x, y,label = ["$(reg)_ uniform discount rate"], lw =1)
savefig(fn,"$(reg).png")
end
#Example for Italy
plotcountry("Italy")
