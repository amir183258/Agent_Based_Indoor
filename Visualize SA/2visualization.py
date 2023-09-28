import matplotlib.pyplot as plt
import numpy as np
import csv
import re

def plot_SA2(parameter, data):
    values = [d[0][parameter] for d in data]
    values = set(values)
    values = sorted(list(values))
    values = [int(v) for v in values]

    # Tricky part: using REGEX
    similars = []
    removed = set()
    for i in range(len(data)):
        temp = []
        current_pattern = data[i][0][0:parameter] + "." + data[i][0][parameter + 1:]
        if current_pattern not in removed:
            for j in range(len(data)):
                if re.search(current_pattern, data[j][0]):
                    temp.append(data[j])
            similars.append(temp)
            removed.add(current_pattern)
    
    # Sorting similars
    sorted_similars = []
    for s in similars:
        temp = []
        for v in values:
            for i in range(len(s)):
                if s[i][0][parameter] == str(v):
                    temp.append(s[i])
        sorted_similars.append(temp)

    # Plot
    fig = plt.figure(figsize=(7, 10), dpi=80)
    ax = fig.add_subplot(1, 1, 1)
    means = [0 for i in range(len(values))]
    count = 0
    precent = [0 for i in range(len(values) - 1)]
    precent_test = [0 for i in range(len(values) - 1)]
    slope = [0 for i in range(len(values) - 1)]
    for s in sorted_similars:
        for i in range(len(s) - 1):
            population1 = 1 #200
            population2 = 1 #200

            """
            if s[i][0][6] == '1':
                population1 = 100
            elif s[i][0][6] == '2':
                population1 = 200
            else:
                population1 = 400

            if s[i + 1][0][6] == '1':
                population2 = 100
            elif s[i + 1][0][6] == '2':
                population2 = 200
            else:
                population2 = 400
            """

            if s[i][1] / population1 - s[i + 1][1] / population2 < 0:
                penColor = "red"
                precent[i] = precent[i] + 1
            elif s[i][1] / population1 - s[i + 1][1] / population2 > 0:
                penColor = "blue"
                precent_test[i] = precent_test[i] + 1
            else:
                penColor = "gray"

            means[i] = means[i] + s[i][1] / population1
            means[i + 1] = means[i + 1] + s[i + 1][1] / population2

            slope[i] = slope[i] + (s[i + 1][1] / population2 - s[i][1] / population1)

            plt.plot([values[i], values[i + 1]], [s[i][1] / population1, s[i + 1][1] / population2], color=penColor, alpha=0.8, linewidth=0.1)
            plt.scatter([values[i], values[i + 1]], [s[i][1] / population1, s[i + 1][1] / population2], color="black", s=0.2)
        count = count + 1

    means = [m / count for m in means]
    slope = [s / count for s in slope]
    for i in range(len(means)):
        plt.scatter(values[i], means[i], color="black", s=300)

    # Plot parameters
    hfont = {"fontname" : "Times New Roman",
             #"weight" : "bold",
             "size" : 40} #24}

    cfont = {"fontname" : "Times New Roman",
             #"weight" : "bold",
             "size" : 32} #16}

    precent = [p / count * 100 for p in precent]
    precent_test = [p / count * 100 for p in precent_test]

    precent_plots = []
    for i in range(len(values) - 1):
        precent_plots.append((values[i] + values[i + 1]) / 2)

    for i in range(len(precent_plots)):
        plt.text(precent_plots[i], 200, str(precent[i])[0:5] + "%", horizontalalignment="center", **cfont)

    plt.gcf().subplots_adjust(left=0.2)
    plt.tick_params(labelright=True)
    plt.xticks(values, ["50", "100", "150"], **cfont)
    plt.yticks(**cfont)

    plot_name = "initialAsymptomatic"

    plt.xlabel(plot_name, **hfont)
    plt.ylabel("Peak day", **hfont)

    #plt.grid(color="#A6A6A6", linestyle='--', linewidth=0.5, axis='y')
    ax.set_facecolor("#F6F6F6")

    plt.savefig("./peak_day/8" + plot_name + ".png")

    print(precent)
    print(precent_test)

    print(f"Slope: {slope}")
    print("Done!")

if __name__ == "__main__":
    data = []
    with open("processedData.csv") as f:
        rawData = csv.reader(f)
        
        for d in rawData:
            temp1 = str(d[0])
            temp2 = float(d[1]) #1: peakDay, 2: peakInfected, 3: totalInfected
            data.append([temp1, temp2])

    plot_SA2(7, data)
    # 0: Distance of Contagion 1.5 2
    # 1: recoveryTime 10 14 18
    # 2: facilityWidth 30 36 40
    # 3: maxMovementsPerDay 250 305 350
    # 4: incubationTime 3 5 7
    # 5: initialInfected 0 5 10 
    # 6: vaccinated 0 20 40
    # 7: incubationTimeRange1 5 10
    # 8: initialAsymptomatic 50 100 150
