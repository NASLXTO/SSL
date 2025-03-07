//+------------------------------------------------------------------+
//|                                                          SSL.mq5 |
//|                                                             Guan |
//|                                   https://github.com/NASLXTO/SSL |
//+------------------------------------------------------------------+
#property copyright "Guan"
#property link      "https://github.com/NASLXTO/SSL"
#property version   "1.10"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   3

//--- Plot BBMC (Baseline)
#property indicator_label1  "BBMC"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrGray, clrDeepSkyBlue, clrRed  // Gray, #00c3ff (Aqua), #ff0062 (Red)
#property indicator_style1  STYLE_SOLID
#property indicator_width1  5

//--- Plot UpperK (Upper Channel)
#property indicator_label2  "UpperK"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrGray, clrDeepSkyBlue, clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- Plot LowerK (Lower Channel)
#property indicator_label3  "LowerK"
#property indicator_type3   DRAW_COLOR_LINE
#property indicator_color3  clrGray, clrDeepSkyBlue, clrRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

//--- Input Parameters
input int      len = 60;             // Baseline Length
input double   multy = 0.2;          // Base Channel Multiplier


//--- Indicator Buffers
double BBMCBuffer[];      // Baseline values
double BBMCColor[];       // Baseline colors
double UpperKBuffer[];    // Upper channel values
double UpperKColor[];     // Upper channel colors
double LowerKBuffer[];    // Lower channel values
double LowerKColor[];     // Lower channel colors
double bbmc_input[];

double rangema[];

//--- Global Variables
int sqrt_len;             // Precomputed square root of len
//int handle_rangema;       // Handle for EMA of true range

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Map indicator buffers
   SetIndexBuffer(0, BBMCBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, BBMCColor, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, UpperKBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, UpperKColor, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4, LowerKBuffer, INDICATOR_DATA);
   SetIndexBuffer(5, LowerKColor, INDICATOR_COLOR_INDEX);
   
   
   //--- Precompute sqrt_len
   sqrt_len = (int)MathRound(MathSqrt(len));
   
   //--- Initialize EMA handle for rangema (EMA of true range)
   // Note: MQL5 doesn't have a direct TR input, so we'll calculate it manually
   //handle_rangema = iMA(NULL, 0, len, 0, MODE_EMA, PRICE_CLOSE);
   //if(handle_rangema == INVALID_HANDLE)
   //{
   //   Print("Failed to create EMA handle for rangema");
   //   return(INIT_FAILED);
   //}
   
   //--- Set indicator short name
   IndicatorSetString(INDICATOR_SHORTNAME, "Custom Keltner Channel");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   //--- Check if enough data is available
   if(rates_total < len + sqrt_len)
      return(0);
   
   //--- Determine start position
   int start = prev_calculated - 1;
   if(start < len + sqrt_len - 1)
      start = len + sqrt_len - 1;
   
   //--- Temporary array for intermediate calculations
   //double bbmc_input[];
   ArrayResize(bbmc_input, rates_total);
   
   
   ArrayResize(rangema, rates_total);
   
   //--- Main calculation loop
   for(int i = start; i < rates_total; i++)
   {
      //--- Calculate WMA for close with periods len/2 and len
      double wma_len2 = WMA(close, i, (int)(len / 2));
      double wma_len = WMA(close, i, len);
      
      //--- Calculate BBMC (Baseline)
      bbmc_input[i] = 2 * wma_len2 - wma_len;
      BBMCBuffer[i] = WMA(bbmc_input, i, sqrt_len);
      
      //--- Calculate True Range (range_1)
      //double range_1;
      
      double range;

      if(i > 0)
      {
         range = MathMax(high[i], close[i-1]) - MathMin(low[i], close[i-1]);
      }
      else
      {
         range = high[i] - low[i];
      }
 
      
      //--- Calculate rangema (EMA of range_1)
      //EMA(range, i, rangema, start); //EMA(range, i);
      //rangema[i] = EMA(range[i], rangema[i-1],i);
      if (rangema.Size() == 0)
      {
      
      rangema[i] = range;
      }
      else 
      {
      rangema[i] = EMA(range, rangema[i-1], i);
      
      }

      
      //--- Calculate UpperK and LowerK
      UpperKBuffer[i] = BBMCBuffer[i] + rangema[i] * multy;
      LowerKBuffer[i] = BBMCBuffer[i] - rangema[i] * multy;
      
      //--- Set colors based on close price position
      if(close[i] > UpperKBuffer[i])
      {
         BBMCColor[i] = 1;    // Aqua (#00c3ff)
         UpperKColor[i] = 1;
         LowerKColor[i] = 1;
      }
      else if(close[i] < LowerKBuffer[i])
      {
         BBMCColor[i] = 2;    // Red (#ff0062)
         UpperKColor[i] = 2;
         LowerKColor[i] = 2;
      }
      else
      {
         BBMCColor[i] = 0;    // Gray
         UpperKColor[i] = 0;
         LowerKColor[i] = 0;
      }
   }
   
   return(rates_total);
}

double WMA(const double &price[], int bar, int period) {
    // 初始化变量
    double norm = 0.0;  // 权重总和
    double sum = 0.0;   // 加权数据总和
    
    // 循环计算加权平均
    for(int i = 0; i < period; i++) {
        // 计算权重，当前柱子 (i = 0) 权重最高
        double weight = (period - i) * period;
        // 累加权重到 norm
        norm += weight;
        // 累加加权数据到 sum，price[bar - i] 是从当前柱子向后回溯
        sum += price[bar - i] * weight;
    }
    
    // 返回加权平均值
    return sum / norm;
}



double EMA(double price, double prev_ema, int period)
{
   double alpha = 2.0 / (period + 1);              // 计算平滑因子 alpha
   return alpha * price + (1 - alpha) * prev_ema;  // 根据公式计算当前 EMA
}
//+------------------------------------------------------------------+
//| Weighted Moving Average (WMA) function                           |
//+------------------------------------------------------------------+
//double WMA(const double &series[], int bar, int period)
//{
//   double sum = 0.0;
//   double weight_sum = 0.0;
//   
//   for(int j = 0; j < period; j++)
//   {
//      if(bar - j < 0)
//         continue;
//      double weight = period - j;  // Linear weights: period, period-1, ..., 1
//      sum += series[bar - j] * weight;
//      weight_sum += weight;
//   }
//   
//   if(weight_sum == 0.0)
//      return(0.0);
//   return(sum / weight_sum);
//}


//+------------------------------------------------------------------+
//| Exponential Moving Average (EMA) function                        |
//+------------------------------------------------------------------+
//double EMA(double price, int bar)
//{
//   static double ema_prev = 0.0;
//   double alpha = 2.0 / (1.0 + (double)len);
//   
//   if(bar == 0)
//      ema_prev = price;
//   else
//      ema_prev = ema_prev + alpha * (price - ema_prev);
//   
//   return(ema_prev);
//}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //if(handle_rangema != INVALID_HANDLE)
   //   IndicatorRelease(handle_rangema);
}
