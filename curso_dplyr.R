#############################################################
############-----Manipulacion de datos con DPLYR-----###############################
############################################################

#Instalar y cargar las librerias que necesitaremos hoy
install.packages("hflights")
install.packages("dplyr")
install.packages("readr")

library(dplyr)
library(hflights)
library(readr)

#Trabajaremos con el dataframe hflights 
#Cada fila representa un vuelo con origen en alguno de los dos aeropuertos internacioanles de Houston (IAH y HOU)
#almacenaremos el dataframe en una variable que llamaremos flights

flights <- hflights[sample(nrow(hflights)),] #aleatorizar el orden de los registros, para propositos didacticos
flights <- as_tibble(flights) #convertir el dataframe en un tibble, para propositos didacticos

#la funcion glimpse(), de dplyr, nos permite echar un vistazo de la informacion contenida en el dataframe
glimpse(flights)



#---------------------VERBO SELECT-------------------------------------#
#utilizamos el verbo select para definir las columnas que deseamos mantener
names(flights)

#select en su forma mas basica
select(flights, FlightNum, UniqueCarrier, Dest)
select(flights, -FlightNum, -UniqueCarrier, -Dest)

#importante: los verbos de dplyr no modificaran el dataframe original
#si deseamos almacenar el resultado debemos asignarlo a una variable, como flighst 2
flights_2 <- select(flights, FlightNum, UniqueCarrier, Dest)
glimpse(flights_2)

#seleccionar/eliminar un rango de columnas
select(flights, FlightNum:Dest)
select(flights, -Year:-Month)

#seleccionar con base en el nombre de la columna
select(flights, contains("Time"))
select(flights, starts_with("Day"))
select(flights, ends_with("Num"))


#PRACTICA
#1) Seleccionar desde la columna "Year" hasta la columna "UniqueCarrier"
#2) Seleccionar todas las columnas del dataframe excepto las ultimas 3 (desde "Cancelled" hasta "Diverted")
#3) Seleccionat todas las columnas cuyo nombre terminen con "Delay"
#Tip: pueden usar names(flights) para ver el nombre de las columnas


#--------------VERBO FILTER----------------------------------#
#utilizamos el verbo filter para mantener o eliminar registros (filas) con base en una o mas condiciones

#operaciones booleanas - repaso
1200 == 1200
1200 != 1200
1200 < 1500
1200 > 1500

'CR' == "CR"
'CR' == "cr"
'CR' %in% c('CR', 'NI', 'GT')

#filtrar con base en una sola condicion
filter(flights, DepTime > 1200)
filter(flights, UniqueCarrier %in% c('AA', 'OO'))

#filtrar registros que no cumplen la condicion (!)
filter(flights, !UniqueCarrier %in% c('AA', 'OO'))

#filtrar con base en dos condiciones, separadas por coma . Ambas deben cumplirse.
filter(flights, 
       UniqueCarrier == "AA", 
       DepTime < 1200)

#filter con base en dos condiciones (cualquiera de las dos puede cumplirse)
filter(flights, Month >= 10 | Month <= 3)


#PRACTICA
#1) Filtrar los vuelos proveneientes de HOU
#2) Filtar los vuelos cuyo tiempo de vuelo (AirTime) fue menor a 120 minutos, en el mes de Diciembre


#--------------VERBO ARRANGE---------------------------------------------------#
#el verbo arrange nos permite ordenar los registros con base en el valor de una columna

#ordenar con base en una variable, en orden ascendente (de menor a mayor) - por defecto
arrange(flights, DepTime)

#ordenar con base en una variable, en orden descendente (de mayor a menor)
arrange(flights, desc(DepTime))


#------------------- VERBO MUTATE ---------------------------------------------#
#el verbo mutate nos permite crear nuevas columnas con base en los valores de una o mas columnas existentes

#vamos a empezar por crear un dataset con solo algunas columnas de interes
#lo llamaremos flights_3
flights_3 <- select(flights, UniqueCarrier, FlightNum, Dest, Distance, AirTime)

#crear una columna nueva: time_hours
#es necesario especificar el nombre de la nueva columna
mutate(flights_3, time_hours = round(AirTime/60, 2))

#crear 2 columnas nuevas, separdas por coma
mutate(flights_3, 
       time_hours = round(AirTime/60, 2),
       carrier_flight = paste(UniqueCarrier, FlightNum))

#una ventaja de mutate es que podemos crear columnas nuevas con base en columnas que acabamos de crear
mutate(flights_3, 
       time_hours = round(AirTime/60, 2),
       speed_mph = Distance/time_hours)

#IMPORTANTE: si asignamos una nueva variable a una columna que ya existe, dplyr la sobreescribira, 
#perdiendo la infomacion original

#un comando muy util a la hora de usar mutate es if_else() para crear categorias binarias
mutate(flights_3, 
       dist_time = if_else(AirTime < 120, "Short", "Long"))

#si necesitamos crear 3 o mas categorias, podemos utilizar case_when()
mutate(flights_3, 
       dist_time = case_when(AirTime < 60 ~ "Short", 
                             AirTime < 120 ~ "Medium",
                             TRUE ~ "Long"))


#PRACTICA

#1)  Usar el verbo select() sobre el dataset flights para seleccionar las columnas:
#    FlightNum, DepTime, TaxiIn y TaxiOut y ActualElapsedTime         
#   asingar el resultado a flights_4

#2)
#a)	Crear una nueva columna llamada TotalTaxiTime: TaxiIn + TaxiOut
#b)	En el mismo comando crear una columna llamada TaxiTimePerc: TotalTaxiTime / ActualElapsedTime

#3) Utilizando flights_4, crear una nueva columna categorica llamada "FlightType" que va a ser" 
#  "early" si DepTime < 1200, "late" en todos los demas casos
# tip: utilizar if_else()


#--------------PIPES Y OPERACIONES EN SECUENCIA -------------------------#

#que tal si queremos realiizar dos o mas operaciones en el dataset, una despues de la otra?
#supongamos que deseamos crear la variables time_hours
#y posteriormente ordenar el dataset con base en este valor
#tenemos varias opciones para lograrlo

#OPCION # 1 - Crear un dataset intermedio y luego alimentarlo a la siguiente operacion
flights_hours <- mutate(flights_3, time_hours = round(AirTime/60, 2))
arrange(flights_hours, time_hours)
#desventaja: empezamos a almacenar mas tablas, lo que eventualmente puede limitar la memoria 

#OPCION # 2 - Anidar las operaciones
arrange(mutate(flights_3, time_hours = round(AirTime/60, 2)), time_hours)
#desventaja: se vuelve dificil de leer y diferenciar que argumento pertenece a que funcion


#OPCION # 3 - Utilizar pipes
#afortunadamente, dplyr cuenta con el pipe (%>%), el cual toma prestado del paquete magrittr
#el pipe nos permite tomar el resultado de una operacion, y alimentarlo a la siguiente
#el atajo para crear un pipe en R Studio es Ctrl + Shift + M


#empecemos con un ejemplo sencillo:
#la funcion round() tiene dos argumentos: 
   #el primero es el numero que deseamos redondear
   #el segundo es la cantidad de decimales
round(7.3468, 2)

#el pipe nos permite alimentar el primer argumento a una funcion "desde afuera" de ella
7.3468 %>% round(2) 

#ahora en combinacion con dplyr para resolver el ejemplo anterior
flights_3 %>% 
  mutate(time_hours = round(AirTime/60, 2)) %>% #1 - crear la nueva variable time_hours con mutate
  arrange(time_hours) #2 - ordenar el dataframe con base en esta nueva variable

#notar que ya no llamamos a flights_3 dentro del mutate(), esto porque con el pipe ya les estamos
#especificando que el primer argumento es el objeto que precede al pipe, flights3 en este caso

#ahora utilizaremos todos los verbos en una sola operacion
flights %>% 
  select(UniqueCarrier, FlightNum, Dest, Distance, AirTime) %>% #1 - seleccionar las columnas de interes
  mutate(time_hours = round(AirTime/60, 2), 
         speed_mph = Distance/time_hours) %>% #2 - crear dos nuevas variables
  filter(time_hours > 4) %>% #3 - filtrar los registros de interes
  arrange(speed_mph) #4 - ordenar el dataset con base en la variables speed_mph


#Por que utilizar pipes?
#1) es mas eficiente escribir codigo (menos lineas)
#2) mayor legibilidad, orden y limpieza en el codigo - mayor facilidad para detectar y corregir errores
#3) es mas facil eliminar o agregar pasos intermedios
#4) estan disenados para trabajar con los verbos de dplyr de una manera intuitiva


#PRACTICA

#1)  Utilizando el dataset flights, realizar las siguientes operaciones en secuencia con pipes:
    #a) seleccionar las columnas FlightNum, UniqueCarrier, TaxiIn, TaxiOut
    #b) filtar los vuelos operados por American Airlines (UniqueCarrier == "AA")
    #c) crear una nueva columna llamada TotalTaxiTime: TaxiIn + TaxiOut
    #d) ordenar los resultados de manera descente con base en TotalTaxiTime
  

#-------------------VERBOS SUMMARIZE y GROUP_BY---------------------------------------------#

#hasta ahora el resultado de nuestras operaciones ha mantenido la misma granularidad del dataset original
#cada fila sigue representando un vuelo
#que tal si quisieramos agregar los datos con base en alguna variables categorica, como UniqueCarrier?
#para esto utilizaremos los verbos summarize() y group_by()


#el verbo summarize() nos permite aplicar funciones agregadas a un set de datos
#por ejemplo: sum(), mean(), max() y sd()
#el resultado es un resumen de todo el dataset: un dataframe de una sola fila

#summarize con una sola metrica agregada: mean()
#al igual que con mutate(), es necesario especificar el nombre de la nueva columna
summarize(flights, avg_distance = mean(Distance))

#podemos utilizar pipes tambien
flights %>% 
  summarize(avg_distance = mean(Distance))

#crear 2 o mas metricas agregadas
flights %>% 
  summarize(avg_distance = mean(Distance), #distancia promedio
            max_distance = max(Distance), #distancia maxima
            flight_count = n(), #conteo de filas
            destinations = n_distinct(Dest)) #conteo de valores distintos en la columna Dest

#una practica comun es combinar summarize con operaciones booleanas
#aprovechamos el hecho de que TRUE y FALSE tienen un valor de 1 y 0 respectivamente
#para determinar que cantidad y porcentaje de observaciones cumplen una condicion

#como lo hariamos en base R
flights$Distance #vector con las distancias
flights$Distance > 500 #vector booleano (TRUE si cumple la condicion, FALSE en caso contrario)
sum(flights$Distance > 500) #cantidad de 1s en el vector (TRUEs)
mean(flights$Distance > 500) #porcentaje de 1s en el vector (% observaciones que cumplen la condicion)

#ahora con dplyr
flights %>% 
  summarize(count_over_500 = sum(Distance > 500),
            perc_over_500 = mean(Distance > 500))

#utilizando mas de una condicion
flights %>% 
  summarize(count_500_to_1000 = sum(Distance > 500 & Distance < 1000),
            perc_500_to_1000 = mean(Distance > 500 & Distance < 1000))


#combinando filter y summarize para obtener las metricas para American Airline unicamente
#notese lo sencillo que resulta agregar un paso intermedio
flights %>% 
  filter(UniqueCarrier == "AA") %>% 
  summarize(count_over_500 = sum(Distance > 500),
            perc_over_500 = mean(Distance > 500))


#--------------GROUP_BY-------------------------#

#que tal si quisieramos calcular las metricas agregadas para cada una de las aerolineas, y no para el total?
#podemos hacerlo agregando un group_by() antes del verbo summarize()
flights %>% 
  group_by(UniqueCarrier) %>% 
  summarize(avg_distance = mean(Distance), #distancia promedio
            max_distance = max(Distance), #distancia maxima
            flight_count = n(), #conteo de filas
            destinations = n_distinct(Dest)) #conteo de valores distintos en la columna Dest

#podemos agregar un arrange() despues del summarize para ordenar los resultados con base en "destinations"
#como el input de este arrange() es el dataset agregado, debemos utilizar los nombres de las columnas de este nuevo dataset
flights %>% 
  group_by(UniqueCarrier) %>% 
  summarize(avg_distance = mean(Distance), #distancia promedio
            max_distance = max(Distance), #distancia maxima
            flight_count = n(), #conteo de filas
            destinations = n_distinct(Dest)) %>% #conteo de valores distintos en la columna Dest
  arrange(desc(destinations))


#PRACTICA

#1) La columna Cancelled, del dataset flights, contiene un 1 si el vuelo fue cancelado y un 0 en caso contrario
  #usando summarize() calcule el total de vuelos cancelados (sum) y el porcentaje de vuelos cancelados (mean) para todo el dataset
  #llame a las columnas cancelled_tot y cancelled_perc

#2) Repita el ejercicio anterior, pero esta vez agrupe por UniqueCarrier para obtener los resultados por aerolinea
   #ordene los resultados de mayor a menor con base en la nueva columna cancelled_perc


#--------------------JOINS CON DPLYR-------------------------#

#-------------------------LEFT JOIN-------------------------#

#Muchas veces tenemos informacion en 2 o mas tablas, y nos interesa unirlas con base en alguna llave 
#para enriquecer nuestra data original con nuevas variables
#en este caso nos interesa tener mas informacion sobre el destino de cada uno de los vuelos del dataset flights

#importamos el csv airports_us_simplified.csv y lo almacenamos en airports
airports <- read_csv("airports_us_simplified.csv")

#utilizamos glimpse para darnos una idea de la informacion que contiene
airports %>% glimpse()


#utilizamos left_join() para "traer" informacion del segundo dataset
#en este caso, vamos "agregar" informacion para cada uno de los destinos
#siempre es importante especificar con base en que columnas vamos a hacer la union
flights_expanded <- left_join(flights, airports, by = c("Dest" = "Code"))

#tenemos dos columnas adicionales provenientes de airports, que corresponden al estado y la ciudad del destino
flights_expanded %>% glimpse()

#pudimos haber hecho el join con pipes de igual manera
flights_expanded <- flights %>% 
  left_join(airports, by = c("Dest" = "Code"))

#podemos combinar left_join con otros verbos de dplyr(), como en el siguiente ejemplo
flights %>% 
  left_join(airports, by = c("Dest" = "Code")) %>% #unir con airports
  select(UniqueCarrier, FlightNum, Dest, State, City) %>% #seleccionar las columnas de interes
  group_by(State) %>% #agrupar por estado 
  summarise(flights_count = n()) %>% #conteo de vuelos por estado
  arrange(desc(flights_count))  #ordenar estados con base en el conteo de vuelos, de mayor a menor




#--------------SEMI JOIN & ANTI JOIN-------------------------#

#En ocasiones, no nos interesa "enriquecer" nuetra data con nuevas columnas provenientes de otra tabla,
#sino filtrar registros de la tabla A existentes en la tabla B, o eliminarlos
#para esta tarea podemos utilizar semi_join() y anti_join()


#importar la tabla worldcup_teams.csv 
world_cups <- read_csv("worldcup_teams.csv")

#echamos un vistazo con glimpse()
world_cups %>% glimpse()

#creamos un dataset de los registros del mundial del 2018 con filter
#lo asignamos a world_cup_2018
world_cup_2018 <- world_cups %>% 
  filter(year == 2018) %>% #filtrar el anno de interes
  select(-year) #eliminar la columna year

world_cup_2018 %>% glimpse()

#hacer lo mismo para el mundial del 2014
#lo asignamos a world_cup_2014
world_cup_2014 <- world_cups %>% 
  filter(year == 2014) %>% #filtrar el anno de interes
  select(-year)

glimpse(world_cup_2014)


#semi_join() nos permite filtar registros del dataset de la izquierda que tambien estan en el dataset de la derecha
#a diferencia del left_join(), no agrega ninguna variable del dataset de la derecha

#que paises presentes en el Mundial 2018 tambien estuvieron presentes en el Mundial 2014?
world_cup_2018 %>% 
  semi_join(world_cup_2014, by = c("Code" = "Code")) 


#anti_join() funciona de manera similar a semi_join(), 
#con la diferencia de que filtra registros del dataset de la izquierda que NO estan en el dataset de la derecha

#que paises presentes en el Mundial 2018 NO estuvieron presentes en el Mundial 2014?
world_cup_2018 %>% 
  anti_join(world_cup_2014, by = c("Code" = "Code")) 


#para cerrar, un doloroso ejemplo con left_join :(
fifa_14 %>% 
  left_join(fifa_18, by = c("Code" = "Code")) %>% 
  filter(Code == "CRI")
