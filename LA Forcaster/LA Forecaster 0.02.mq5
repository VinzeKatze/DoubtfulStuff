//-----------------------------
// Это Expert для MetaTraider (alglib в последнем предустановлен)
// 
// Основная причина его существования - опробовать матемаческий метод прогнозирования временных рядов
// на основе локальной аппроксимации. Теория динамического хаоса, фазовые пространства, многоменрные вектора и все такое...
// 
// ВНИМАНИЕ! ЭТО СУПЕР-ТЕСТОВЫЙ ПРОТОТИП!
// НЕ ПРИГОДЕН ДЛЯ ИСПОЛЬЗОВАНИЯ!
// 
// Также код написан не просто плохо, а СУПЕР ПЛОХО.
// В свое оправдание могу сказать, что не собирался его развивать здесь изначально.
// Хотел лишь поэкспериментировать с методом в уютной среде терменала.
//-----------------------------
//
#property copyright "VinzeKatze"
#property link      ""
#property version   "0.02"
#include <Math\Alglib\alglib.mqh>

//Перечисление режимов
enum ENUM_LA_MODE
  {
   LA_1_It, //ЛA-1 ИсП
   LA_1_D, //ЛA-1 П
   LA_0_It, //ЛA-0 ИсП 
   LA_0_D, //ЛA-0 П
  };


//Перечисление обрабатываемых данных
enum ENUM_DATA_TYPE
  {
   MidData, //Средние цены (откр, закр)
   MidFullData, //Средние цены (вся свеча)
  };
 
//Перечисление видов норм
enum ENUM_NORMS
   {
   Evklid, //Евклидова норма
   Gelder, //Гёльдерова норма
   Manhet, //Манхэттенское расстояние
   };

//Входы
input group "Параметры прогнозирования"
input ENUM_LA_MODE ForecastMode = LA_1_It; //Режим
input int Dimension=20; //Размерность
input ENUM_NORMS NormType=Manhet; //Вид нормы
input int KoefNeighbors=3; //Коэф. кол-ва соседей
input int ForecastSteps=100; //Шагов прогнозирования

input group "Параметры данных"
input ENUM_TIMEFRAMES ForecastPeriod=PERIOD_M5; //Период
input ENUM_DATA_TYPE DataType=MidFullData; //Тип данных
input int MaxBarsCalc=25000; //Макс. кол-во отсчетов
input int DataSmoorth=1; //Сглаживание данных

input group "Параметры отображения"
input color StartLineColor=clrRed; //Цвет стартовой линии
input color FLineColor=clrRed; //Цвет линии прогноза
input ENUM_LINE_STYLE FLineStyle=STYLE_SOLID; //Стиль линии
input int FlineWidth=3; //Толщина линии


//---Глобальные переменные
datetime StartPoint=TimeCurrent();
int StartShift=0;
int Neighbors=0;

double OpenRecoiver[];
double CloseRecoiver[];
double MaxRecoiver[];
double MinRecoiver[];
double DataTransmitter[];
double DataPreTransmitter[];

double Vector[];

double DataNorms[];
int NeighborsShifts[];
double NeighborsPrices[];

double ForecastData[];
double OutputData[];



//---Базовые Функции

//---Евклидово расстояние между векторами
double ENorm(double &dt[], double &vec[], int pos)
  {
   int dem=ArraySize(vec);
   double summ=0;
   for(int j=0; j<dem; j++)
     {summ += MathPow(vec[j]-dt[j+pos],2);}
   return (MathSqrt(summ));
  };
  
//---Гёльдерово расстояние между векторами
double GNorm(double &dt[], double &vec[], int pos)
  {
   int dem=ArraySize(vec);
   double summ=0;
   for(int j=0; j<dem; j++)
     {summ += MathPow(MathAbs(vec[j]-dt[j+pos]),dem);}
   return (MathPow(summ,1/(double)dem));
  }; 
  
//---Манхэттенское расстояние между векторами
double MNorm(double &dt[], double &vec[], int pos)
  {
   int dem=ArraySize(vec);
   double summ=0;
   for(int j=0; j<dem; j++)
     {summ += MathAbs(vec[j]-dt[j+pos]);}
   return (summ);
  };     


//---Скалярное произведение векторов
double VxVScal(double &x[], double &y[])
   {int n=ArraySize(x);
    double Sum=0;
    for(int j=0; j<n; j++)
         {Sum+=x[j]*y[j];}
    return(Sum);}


//---Сглаживание данных
double SmoorthFunk(double &data[], int SmoorthDeap, int pos)
   {
   double summ=0;
   for(int j=0; j<=SmoorthDeap; j++)
      {summ += data[j+pos];
      }
   return(summ/(SmoorthDeap+1));
   }


//------------------------------------------------------------------
//                           Инициализация
//------------------------------------------------------------------
int OnInit()
  {
//---Переворот массивов
   ArraySetAsSeries(OpenRecoiver,true);
   ArraySetAsSeries(CloseRecoiver,true);
   ArraySetAsSeries(MinRecoiver,true);
   ArraySetAsSeries(MaxRecoiver,true);
   ArraySetAsSeries(DataPreTransmitter,true);
   ArraySetAsSeries(DataTransmitter,true);

//---Создание стартовой линии
   ObjectCreate(0,"StartLine",OBJ_VLINE,0,TimeCurrent(),0);
   ObjectSetInteger(0,"StartLine",OBJPROP_COLOR,StartLineColor);
   ObjectSetInteger(0,"StartLine",OBJPROP_SELECTABLE,true);
   ObjectSetInteger(0,"StartLine",OBJPROP_SELECTED,true);

//---Создание кнопки РАСЧЕТ
   ObjectCreate(0,"BBButon",OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,"BBButon",OBJPROP_CORNER,CORNER_RIGHT_LOWER);
   ObjectSetInteger(0,"BBButon",OBJPROP_XDISTANCE,70);
   ObjectSetInteger(0,"BBButon",OBJPROP_YDISTANCE,25);
   ObjectSetInteger(0,"BBButon",OBJPROP_XSIZE,70);
   ObjectSetInteger(0,"BBButon",OBJPROP_YSIZE,25);
   ObjectSetInteger(0,"BBButon",OBJPROP_STATE,false);
   ObjectSetString(0,"BBButon",OBJPROP_TEXT,"Расчет");
   

//---
   ChartRedraw();
   return(INIT_SUCCEEDED);
  }



//------------------------------------------------------------------
//                         Де-Инициализация
//------------------------------------------------------------------
void OnDeinit(const int reason)
  {
   ResetLastError();
   ObjectDelete(0,"BBButon");
   ObjectDelete(0,"StartLine");
  }


//------------------------------------------------------------------
//                              Тики
//------------------------------------------------------------------
void OnTick()
  {
   
  }
//------------------------------------------------------------------
//                          События графика
//------------------------------------------------------------------
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {

//Кнопка Расчет
   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="BBButon" && ObjectGetInteger(0,"BBButon",OBJPROP_STATE))
     {EventChartCustom(0,42,1,0,"fo23bcUb340b");}




//-------------------------------------------------------------
//----------------------Событие расчета------------------------
//-------------------------------------------------------------
   if(id==1042 && sparam=="fo23bcUb340b")
     {
      //----------------------Подготовка данных----------------------
      ChartRedraw();
      Print(EnumToString(ForecastPeriod), ": доступно ", SeriesInfoInteger(NULL,ForecastPeriod,SERIES_BARS_COUNT), " баров");
      StartShift = iBarShift(NULL,ForecastPeriod,(datetime)ObjectGetInteger(0,"StartLine",OBJPROP_TIME),false)+1;
      StartPoint = iTime(NULL,ForecastPeriod,StartShift);

      int StopShift = 0;
      if(iBarShift(NULL,ForecastPeriod,(datetime)SeriesInfoInteger(NULL,ForecastPeriod,SERIES_FIRSTDATE),false) < MaxBarsCalc-1)
         StopShift = iBarShift(NULL,ForecastPeriod,(datetime)SeriesInfoInteger(NULL,ForecastPeriod,SERIES_FIRSTDATE),false)+1;
      else
         StopShift = MaxBarsCalc;

      //Подготовка приемных массивов
      ArrayFree(DataTransmitter);
      ArrayResize(DataTransmitter,StopShift-DataSmoorth,0);
      ArrayFree(DataPreTransmitter);
      ArrayResize(DataPreTransmitter,StopShift,0);
      
      //Заполнение приемного массива нужным типом данных
      //Если средние
      if(DataType==MidData)
        {
         CopyOpen(NULL,ForecastPeriod,0,StopShift,OpenRecoiver);
         CopyClose(NULL,ForecastPeriod,0,StopShift,CloseRecoiver);
         for(int i=0; i<StopShift-1 && !IsStopped(); i++)
           {DataPreTransmitter[i]=(OpenRecoiver[i]+CloseRecoiver[i])/2;}
        }
      //Если средние (мин, макс)
      if(DataType==MidFullData)
        {
         CopyOpen(NULL,ForecastPeriod,0,StopShift,OpenRecoiver);
         CopyClose(NULL,ForecastPeriod,0,StopShift,CloseRecoiver);
         CopyHigh(NULL,ForecastPeriod,0,StopShift,MaxRecoiver);
         CopyLow(NULL,ForecastPeriod,0,StopShift,MinRecoiver);
         for(int i=0; i<StopShift-1 && !IsStopped(); i++)
           {DataPreTransmitter[i]=(OpenRecoiver[i]+CloseRecoiver[i]+MaxRecoiver[i]+MinRecoiver[i])/4;}
        }
      
      //Сглаживание данных
      for(int i=0; i<StopShift-DataSmoorth && !IsStopped(); i++)
         {DataTransmitter[i]=SmoorthFunk(DataPreTransmitter,DataSmoorth,i);}
    
      //Отчистка промежуточных массивов (на всякий случай)
      ArrayFree(OpenRecoiver);
      ArrayFree(CloseRecoiver);
      ArrayFree(MaxRecoiver);
      ArrayFree(MinRecoiver);


      //-------------------Расчеты--------------------------------


      //Собираем стартовый вектор
      ArrayFree(Vector);
      ArrayResize(Vector,Dimension,0);
      for(int i=0; i<Dimension; i++)
        {Vector[i]=DataTransmitter[i+StartShift];}
      
      int DataNormsSize = ArraySize(DataTransmitter)-StartShift-Dimension;
      
      //Подготавливаем расчетный массив для норм
      ArrayFree(DataNorms);
      ArrayResize(DataNorms,DataNormsSize,0);
      
      //Кол-во сосдей в зависимости от режима
      if(ForecastMode==LA_1_It || ForecastMode==LA_1_D)
         Neighbors = KoefNeighbors*(Dimension+1);
      if(ForecastMode==LA_0_It || ForecastMode==LA_0_D)
         Neighbors = KoefNeighbors;

      //Подготовка массива координат соседей
      ArrayFree(NeighborsShifts);
      ArrayResize(NeighborsShifts,Neighbors,0);
      //Подготовка массива цен соседей
      ArrayFree(NeighborsPrices);
      ArrayResize(NeighborsPrices,Neighbors,0);
      
      //Подготовка массива прогнозов
      ArrayFree(ForecastData);
      ArrayResize(ForecastData,ForecastSteps,0);
      //Подготовка массива выхода
      ArrayFree(OutputData);
      ArrayResize(OutputData,ForecastSteps,0);







      //---------------ЛОКАЛЬНАЯ АППРОКСИМАЦИЯ 0 ПОРЯДКА ИТЕРАТИВНАЯ С ПЕРЕСЧЕТОМ----------------------
      if(ForecastMode==LA_0_It)
        {
         //-------------Тело цикла
         for(int stp=0; stp<ForecastSteps; stp++)
           {
         //Пересборка стартового вектора
           if(stp>0)
           {for(int i=Dimension-1; i>=0; i--)
                 {if     (i>=1) Vector[i]=Vector[i-1];
                  else  Vector[i]=ForecastData[stp-1];}}

         //Заполняем массив норм
         for(int i=0; i<DataNormsSize; i++)
           {if(NormType==Evklid) DataNorms[i]=ENorm(DataTransmitter,Vector,i+StartShift);
            if(NormType==Gelder) DataNorms[i]=GNorm(DataTransmitter,Vector,i+StartShift);
            if(NormType==Manhet) DataNorms[i]=MNorm(DataTransmitter,Vector,i+StartShift);}

         //Узнаем максимальное значение норм
         double NormMax = DataNorms[ArrayMaximum(DataNorms)];

         //Заполнение массива координат соседей
         for(int i=0; i<Neighbors; i++)
           {NeighborsShifts[i]=ArrayMinimum(DataNorms,1,WHOLE_ARRAY)+StartShift;
            DataNorms[NeighborsShifts[i]-StartShift]=NormMax;}
       
            double MidSumm = 0;
            //Цены t+1 соседей
            for(int i=0; i<Neighbors; i++)
               {NeighborsPrices[i]=DataTransmitter[NeighborsShifts[i]-1];
                MidSumm+=NeighborsPrices[i]/Neighbors;}
              
            //Составление прогноза
            ForecastData[stp]=MidSumm;
           
         //Печать прогресса рассчета
         Print("Прогресс расчета: ", stp+1, "/", ForecastSteps);
           }
        }






      //---------------ЛОКАЛЬНАЯ АППРОКСИМАЦИЯ 0 ПОРЯДКА ПРЯМАЯ----------------------
      if(ForecastMode==LA_0_D)
        {
         //Заполняем массив норм
         for(int i=0; i<DataNormsSize; i++)
           {if(NormType==Evklid) DataNorms[i]=ENorm(DataTransmitter,Vector,i+StartShift);
            if(NormType==Gelder) DataNorms[i]=GNorm(DataTransmitter,Vector,i+StartShift);
            if(NormType==Manhet) DataNorms[i]=MNorm(DataTransmitter,Vector,i+StartShift);}

         //Узнаем максимальное значение норм
         double NormMax = DataNorms[ArrayMaximum(DataNorms)];

         //Заполнение массива координат соседей
         for(int i=0; i<Neighbors; i++)
           {NeighborsShifts[i]=ArrayMinimum(DataNorms,ForecastSteps,WHOLE_ARRAY)+StartShift;
            DataNorms[NeighborsShifts[i]-StartShift]=NormMax;}
       
         //-------------Тело цикла
         for(int stp=0; stp<ForecastSteps; stp++)
           {double MidSumm = 0;

            //Цены t+1 соседей
            for(int i=0; i<Neighbors; i++)
               {NeighborsPrices[i]=DataTransmitter[NeighborsShifts[i]-1-stp];
                MidSumm+=NeighborsPrices[i]/Neighbors;}
              
            //Составление прогноза
            ForecastData[stp]=MidSumm;
           
            //Печать дат соседей для проверки
            for(int i=0; i<Neighbors && stp==ForecastSteps-1; i++)
               {Print("Время соседа N", i+1 , ": ",iTime(NULL,ForecastPeriod,NeighborsShifts[i]+StartShift));}
           }
           
           //Первая доступная дата
             Print("Первая доступная дата: ", iTime(NULL,ForecastPeriod,StopShift-1));
        }

     
     

     


      //---------------ЛОКАЛЬНАЯ АППРОКСИМАЦИЯ 1 ПОРЯДКА ИТЕРАТИВНАЯ С ПЕРЕСЧЕТОМ----------------------
      if(ForecastMode==LA_1_It)
        {
         //-------------Тело цикла
         for(int stp=0; stp<ForecastSteps; stp++)
         {
            //Пересборка стартового вектора
            if(stp>0)
            {for(int i=Dimension-1; i>=0; i--)
                  {if     (i>=1) Vector[i]=Vector[i-1];
                   else  Vector[i]=ForecastData[stp-1];}}
                            
         //Заполняем массив норм
         for(int i=0; i<DataNormsSize; i++)
           {if(NormType==Evklid) DataNorms[i]=ENorm(DataTransmitter,Vector,i+StartShift);
            if(NormType==Gelder) DataNorms[i]=GNorm(DataTransmitter,Vector,i+StartShift);
            if(NormType==Manhet) DataNorms[i]=MNorm(DataTransmitter,Vector,i+StartShift);}

         //Узнаем максимальное значение норм
         double NormMax = DataNorms[ArrayMaximum(DataNorms)];
         
         //Заполнение массива координат соседей
         for(int i=0; i<Neighbors; i++)
           {
            NeighborsShifts[i]=ArrayMinimum(DataNorms,1,WHOLE_ARRAY)+StartShift;
            DataNorms[NeighborsShifts[i]-StartShift]=NormMax;
           }

         //Все-таки пытаемся решить эту херь
         //Создаем матрицы
         CMatrixDouble L(Neighbors,Neighbors); //E-I*I^T/I^T*I
         CMatrixDouble X(Neighbors,Dimension); //X
         CMatrixDouble Xt(Dimension,Neighbors); //Xtransp
         CMatrixDouble XtL(Dimension,Neighbors); //вначале Xt*L, потом собирает результат
         CMatrixDouble XtLX(Dimension,Dimension); //Xt*L*X
         //И немного векторов
         double Xa[]; ArrayFree(Xa); ArrayResize(Xa,Neighbors);
         
         //Вектор параметров
         double Avector[]; ArrayFree(Avector); ArrayResize(Avector,Dimension);
         //Константа
         double Aconst=0;
                  
         //Заполняем матрицу E-I*I^T/I^T*I
         for(int i=0; i<Neighbors; i++)
            {for(int j=0; j<Neighbors; j++)
               { if(j==i) L[i].Set(j, ((double)Neighbors-1)/(double)Neighbors);
                 else L[i].Set(j,(-1/(double)Neighbors));}                  
            }
         
         //Заполняем матрицу пространсва задержек соседей X
         for(int i=0; i<Neighbors; i++)
            {for(int j=0; j<Dimension; j++)
                {X[i].Set(j, DataTransmitter[NeighborsShifts[i]+j]);}                
            }
            
         //Заполняем обратную матрицу пространсва задержек соседей Xt потомучто нахер идите со своим алглибом, вот почему
         for(int i=0; i<Dimension; i++)
            {for(int j=0; j<Neighbors; j++)
                {Xt[i].Set(j, DataTransmitter[NeighborsShifts[j]+i]);}                
            }
         
         //Заполняем вектор прогнозов соседей
         for(int i=0; i<Neighbors; i++)
            {NeighborsPrices[i]=DataTransmitter[NeighborsShifts[i]-1];}
         
         //Расчитываем вектор параметров
         //Пробуем посчтитать Xt*L алглибом и не обосраться
         CAblas::RMatrixGemm(Dimension,Neighbors,Neighbors,1, Xt,0,0,0, L,0,0,0, 0,XtL,0,0);
         //Опять пробуем посчтитать Xt*L*X алглибом и недеемся, что не обосрались
         CAblas::RMatrixGemm(Dimension,Dimension,Neighbors,1, XtL,0,0,0, X,0,0,0, 0,XtLX,0,0);
         //Ох, оно правильно работает вообще? Я ХЗ. Ищем обратную матрицу умноженную на XtL. РЕЗУЛЬТАТ ТЕПЕРЬ В XtL
         CAblas::RMatrixLeftTrsM(Dimension,Neighbors, XtLX,0,0,false,false,0,XtL,0,0);
         //А теперь умножаем все на вектор прогнозов соседей и молимся, что все ок
         CAblas::RMatrixMVect(Dimension,Neighbors,XtL,0,0,0, NeighborsPrices,0, Avector,0);
         
         //Расчитываем константу
         //Последние алглиб... дале в ручную. Расчет произведения Матрицы X на вектор параметров
         CAblas::RMatrixMVect(Neighbors,Dimension,X,0,0,0, Avector,0, Xa,0); 
         //Расчитываем константу
         for(int i=0; i<Neighbors; i++)
            {Aconst+=(NeighborsPrices[i]-Xa[i]);}
         Aconst=Aconst/Neighbors;        

         //Составление прогноза
         ForecastData[stp]=Aconst+VxVScal(Vector,Avector);
         
         //Печать прогресса рассчета
         Print("Прогресс расчета: ", stp+1, "/", ForecastSteps);
         }

        }







      //---------------ЛОКАЛЬНАЯ АППРОКСИМАЦИЯ 1 ПОРЯДКА ПРЯМАЯ----------------------
      if(ForecastMode==LA_1_D)
        {
         //Заполняем массив норм
         for(int i=0; i<DataNormsSize; i++)
           {if(NormType==Evklid) DataNorms[i]=ENorm(DataTransmitter,Vector,i+StartShift);
            if(NormType==Gelder) DataNorms[i]=GNorm(DataTransmitter,Vector,i+StartShift);
            if(NormType==Manhet) DataNorms[i]=MNorm(DataTransmitter,Vector,i+StartShift);}

         //Узнаем максимальное значение норм
         double NormMax = DataNorms[ArrayMaximum(DataNorms)];
         
         //Заполнение массива координат соседей
         for(int i=0; i<Neighbors; i++)
           {
            NeighborsShifts[i]=ArrayMinimum(DataNorms,ForecastSteps,WHOLE_ARRAY)+StartShift;
            DataNorms[NeighborsShifts[i]-StartShift]=NormMax;
           }

         //-------------Тело цикла
         for(int stp=0; stp<ForecastSteps; stp++)
         {
         //Все-таки пытаемся решить эту херь
         //Создаем матрицы
         CMatrixDouble L(Neighbors,Neighbors); //E-I*I^T/I^T*I
         CMatrixDouble X(Neighbors,Dimension); //X
         CMatrixDouble Xt(Dimension,Neighbors); //Xtransp
         CMatrixDouble XtL(Dimension,Neighbors); //вначале Xt*L, потом собирает результат
         CMatrixDouble XtLX(Dimension,Dimension); //Xt*L*X
         //И немного векторов
         double Xa[]; ArrayFree(Xa); ArrayResize(Xa,Neighbors);
         
         //Вектор параметров
         double Avector[]; ArrayFree(Avector); ArrayResize(Avector,Dimension);
         //Константа
         double Aconst=0;
                  
         //Заполняем матрицу E-I*I^T/I^T*I
         for(int i=0; i<Neighbors; i++)
            {for(int j=0; j<Neighbors; j++)
               { if(j==i) L[i].Set(j, ((double)Neighbors-1)/(double)Neighbors);
                 else L[i].Set(j,(-1/(double)Neighbors));}                  
            }
         
         //Заполняем матрицу пространсва задержек соседей X
         for(int i=0; i<Neighbors; i++)
            {for(int j=0; j<Dimension; j++)
                {X[i].Set(j, DataTransmitter[NeighborsShifts[i]+j]);}                
            }
            
         //Заполняем обратную матрицу пространсва задержек соседей Xt потомучто нахер идите со своим алглибом, вот почему
         for(int i=0; i<Dimension; i++)
            {for(int j=0; j<Neighbors; j++)
                {Xt[i].Set(j, DataTransmitter[NeighborsShifts[j]+i]);}                
            }
         
         //Заполняем вектор прогнозов соседей
         for(int i=0; i<Neighbors; i++)
            {NeighborsPrices[i]=DataTransmitter[NeighborsShifts[i]-1-stp];}
         
         //Расчитываем вектор параметров
         //Пробуем посчтитать Xt*L алглибом и не обосраться
         CAblas::RMatrixGemm(Dimension,Neighbors,Neighbors,1, Xt,0,0,0, L,0,0,0, 0,XtL,0,0);
         //Опять пробуем посчтитать Xt*L*X алглибом и недеемся, что не обосрались
         CAblas::RMatrixGemm(Dimension,Dimension,Neighbors,1, XtL,0,0,0, X,0,0,0, 0,XtLX,0,0);
         //Ох, оно правильно работает вообще? Я ХЗ. Ищем обратную матрицу умноженную на XtL. РЕЗУЛЬТАТ ТЕПЕРЬ В XtL
         CAblas::RMatrixLeftTrsM(Dimension,Neighbors, XtLX,0,0,false,false,0,XtL,0,0);
         //А теперь умножаем все на вектор прогнозов соседей и молимся, что все ок
         CAblas::RMatrixMVect(Dimension,Neighbors,XtL,0,0,0, NeighborsPrices,0, Avector,0);
         
         //Расчитываем константу
         //Последние алглиб... дале в ручную. Расчет произведения Матрицы X на вектор параметров
         CAblas::RMatrixMVect(Neighbors,Dimension,X,0,0,0, Avector,0, Xa,0); 
         //Расчитываем константу
         for(int i=0; i<Neighbors; i++)
            {Aconst+=(NeighborsPrices[i]-Xa[i]);}
         Aconst=Aconst/Neighbors;        

         //Составление прогноза
         ForecastData[stp]=Aconst+VxVScal(Vector,Avector);
         
         //Печать прогресса рассчета
         Print("Прогресс расчета: ", stp+1, "/", ForecastSteps);
         }

        }

   
      //Либо атавизм, либо задел на будущее
      for(int i=0; i<ForecastSteps; i++)
         {OutputData[i]=ForecastData[i];}


      //Отрисовка прогноза объектами, да бть через жопу пошло бы оно все
      for(int i=0; i<ForecastSteps-1; i++)
        {ObjectCreate(0,"Line" + IntegerToString(i),OBJ_TREND,0,
                      StartPoint+(i+1)*PeriodSeconds(ForecastPeriod),OutputData[i],
                      StartPoint+(i+2)*PeriodSeconds(ForecastPeriod),OutputData[i+1]);
         ObjectSetInteger(0,"Line" + IntegerToString(i),OBJPROP_COLOR,FLineColor);
         ObjectSetInteger(0,"Line" + IntegerToString(i),OBJPROP_STYLE,FLineStyle);
         ObjectSetInteger(0,"Line" + IntegerToString(i),OBJPROP_WIDTH,FlineWidth);}


      //Возврат кнопки
      ObjectSetInteger(0,"BBButon",OBJPROP_STATE,false);
      ChartRedraw();
     }




  }
//-------------------------------------------------------------------
//+------------------------------------------------------------------+
/*                           ЗАГАЖНИК











*/
