import numpy as np
import csv
import matplotlib.pyplot as plt



if __name__ == "__main__":
    # Open results file
    data = []
    headers = []

    files = ["sa_1_1.csv", "sa_1_2.csv", "sa_1_3.csv", "sa_1_4.csv",
             "sa_1_5.csv", "sa_1_6.csv", "sa_1_7.csv", "sa_2.csv",
             "sa_2_2.csv", "sa_4_1.csv", "sa_5_1.csv"]

    # First file, contains 8K records.
    for file in files:
        with open(file) as f:
            rawData = csv.reader(f)
            
            dataIndex = 6
            i = 0
            for d in rawData:
                if i > dataIndex:
                    temp = [float(stringData) for stringData in d]
                    data.append(temp)
                if i == 6:
                    headers = d

                i = i + 1

    data = np.array(data)

    for i in range(data.shape[1]):
        print(f"{i}: {headers[i]}: ", end="")
        if len(set(data[:, i])) <= 3:
            print(f"{set(data[:, i])}")
        else:
            print("")

    processedData = []
    # Determine the scenario
    for i in range(data.shape[0]):
        ID = ""
        # 1) Distance of Contagion
        if data[i, 3] == 1.5:
            ID = ID + '1'
        elif data[i, 3] == 2:
            ID = ID + '2'

        # 2) Recovery Timer
        if data[i, 5] == 10:
            ID = ID + '1'
        elif data[i, 5] == 14:
            ID = ID + '2'
        elif data[i, 5] == 18:
            ID = ID + '3'

        # 3) Facility Width
        if data[i, 6] == 30:
            ID = ID + '1'
        elif data[i, 6] == 36:
            ID = ID + '2'
        elif data[i, 6] == 40:
            ID = ID + '3'

        # 4) Max movements per day 
        if data[i, 7] == 250:
            ID = ID + '1'
        elif data[i, 7] == 305:
            ID = ID + '2'
        elif data[i, 7] == 350:
            ID = ID + '3'

        # 5) Incubation time
        if data[i, 15] == 3:
            ID = ID + '1'
        elif data[i, 15] == 5:
            ID = ID + '2'
        elif data[i, 15] == 7:
            ID = ID + '3'

        # 6) Initial number of infected agents 
        if data[i, 29] == 0:
            ID = ID + '1'
        elif data[i, 29] == 5:
            ID = ID + '2'
        elif data[i, 29] == 10:
            ID = ID + '3'

        # 7) Number of vaccinated
        if data[i, 30] == 0:
            ID = ID + '1'
        elif data[i, 30] == 20:
            ID = ID + '2'
        elif data[i, 30] == 40:
            ID = ID + '3'

        # 8) Number of asymptomatic agents 
        if data[i, 31] == 50:
            ID = ID + '1'
        elif data[i, 31] == 100:
            ID = ID + '2'
        elif data[i, 31] == 150:
            ID = ID + '3'

        temp = []
        temp.append(ID)
        temp.append(data[i, -1])
        temp.append(data[i, -2])
        temp.append(data[i, -3])

        processedData.append(temp)

    IDs = [string[0] for string in processedData]
    IDs = set(IDs)
    print(len(IDs))

    cumulativeData = []
    for i in range(len(processedData)):
        if processedData[i][0] in IDs:
            temp = []
            temp.append(processedData[i][0])
            temp.append(0)
            temp.append(0)
            temp.append(0)
            count = 0

            for j in range(len(processedData)):
                if processedData[i][0] == processedData[j][0]:
                    temp[1] = temp[1] + processedData[j][1]
                    temp[2] = temp[2] + processedData[j][2]
                    temp[3] = temp[3] + processedData[j][3]
                    count = count + 1

            temp[1] = temp[1] / count
            temp[2] = temp[2] / count
            temp[3] = temp[3] / count

            cumulativeData.append(temp)
            IDs.remove(temp[0])

    # Write file
    with open("processedData.csv", 'w') as f:
        for d in cumulativeData:
            f.write(d[0] + ", " + str(d[1]) + ", " + str(d[2]) + ", " + str(d[3]) + "\n")

    exit()

    processedData = []
    # Determine the scenario
    for i in range(data.shape[0]):
        ID = ""
        # 1) indirectTransmissionDistance
        if data[i, 1] == 1:
            ID = ID + '1'
        else:
            ID = ID + '2'

        # 2) distanceOfContagion
        if data[i, 3] == 1:
            ID = ID + '1'
        elif data[i, 3] == 2:
            ID = ID + '2'
        else:
            ID = ID + '3'

        # 3) recoveryTime
        if data[i, 5] == 7:
            ID = ID + '1'
        elif data[i, 5] == 14:
            ID = ID + '2'
        else:
            ID = ID + '3'

        # 4) facilityWidth 
        if data[i, 6] == 20:
            ID = ID + '1'
        elif data[i, 6] == 36:
            ID = ID + '2'
        else:
            ID = ID + '3'

        # 5) maxMovementsPerDay
        if data[i, 7] == 10:
            ID = ID + '1'
        else:
            ID = ID + '2'

        # 6) secretionRate
        if data[i, 13] == 0.01:
            ID = ID + '1'
        elif data[i, 13] == 0.23:
            ID = ID + '2'
        else:
            ID = ID + '3'

        # 7) populationSize
        if data[i, 14] == 100:
            ID = ID + '1'
        elif data[i, 14] == 200:
            ID = ID + '2'
        else:
            ID = ID + '3'

        # 8) incubationTime
        if data[i, 15] == 5:
            ID = ID + '1'
        else:
            ID = ID + '2'

        # 9) decayRate
        if data[i, 20] == 0.05:
            ID = ID + '1'
        elif data[i, 20] == 0.1732:
            ID = ID + '2'
        else:
            ID = ID + '3'

        temp = []
        temp.append(ID)
        temp.append(data[i, -1])

        processedData.append(temp)

    IDs = [string[0] for string in processedData]
    IDs = set(IDs)

    cumulativeData = []
    for i in range(len(processedData)):
        if processedData[i][0] in IDs:
            temp = []
            temp.append(processedData[i][0])
            temp.append(0)
            count = 0

            for j in range(len(processedData)):
                if processedData[i][0] == processedData[j][0]:
                    temp[1] = temp[1] + processedData[j][1]
                    count = count + 1

            temp[1] = temp[1] / count

            cumulativeData.append(temp)
            IDs.remove(temp[0])

    # Write file
    with open("processedData.csv", 'w') as f:
        for d in cumulativeData:
            f.write(d[0] + ", " + str(d[1]) + "\n")
