//+------------------------------------------------------------------+
//|                                                    sample_ea.mq5 |
//|                               Simple Moving Average Crossover EA |
//|                                             textyping2@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Mike"
#property link      "textyping2@gmail.com"
#property version   "1.00"

input    int      fastMAPeriod      = 12;       // MA Period Fast
input    int      slowMAPeriod      = 26;       // MA Period Slow
input    double   lotSize           = 0.1;      // Lot Size
input    double   stopLoss          = 200;      // Stop Loss, Points (0 - OFF)
input    double   takeProfit        = 100;      // Take Profit, Points (0 - OFF)
input    int      magic             = 168737;   // Magic Number                                  
input    int      slippage          = 100;      // Slippage
input    string   comment           = "";       // Comment

int      handleFast, handleSlow;

datetime curCandle;

double   _point, Ask, Bid;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   _point = _Point;
   
// Get Handles for MA fast and MA slow

   handleFast = iMA (_Symbol, _Period, fastMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   handleSlow = iMA(_Symbol, _Period, slowMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   
   curCandle = iTime (_Symbol, _Period, 0);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if (curCandle != iTime (_Symbol, _Period, 0))
    {
     curCandle = iTime (_Symbol, _Period, 0);
     
     
     if (!openedPositions())
      {
       calculateAskBid();
       
       double fast = getIndicatorValue (handleFast, 0, 1);
       double slow = getIndicatorValue (handleSlow, 0, 1);
       double fastPrev = getIndicatorValue (handleFast, 0, 2);
       double slowPrev = getIndicatorValue (handleSlow, 0, 2);

       if (fast > slow && fastPrev <= slowPrev) openBuy();
       else if (fast < slow && fastPrev >= slowPrev) openSell();
      }
    }
  }
  
//--------------------------------------------------------------------

double getIndicatorValue (int indHandle, int indBuffer, int indShift)
 {
  double res[1];
  
  if (CopyBuffer (indHandle, indBuffer, indShift, 1, res) != 1) 
   {
    return 0;
   }
   
  return res[0];
 }

//+------------------------------------------------------------------+ 

bool openedPositions()
  {
   bool z = false;
   if (PositionsTotal() == 0) z = false;
   else
    {
     string deal_symbol = "";
     long deal_magic = 0;

     for (int i = PositionsTotal() - 1; i >= 0; i--)
      {
       deal_symbol = PositionGetSymbol(i);
       deal_magic = PositionGetInteger(POSITION_MAGIC);
       
       if (deal_symbol == _Symbol && deal_magic == magic)
        {
         z = true; 
         break;
        }
      }
    }
   return(z);
  }

//+------------------------------------------------------------------+ 

void openBuy()
 {
  double SL;
  double TP;
  if (stopLoss == 0) SL = 0;
  else SL = Ask - stopLoss * _point;
  if (takeProfit == 0) TP = 0;
  else TP = Ask + takeProfit * _point;

  bool Ans = false;
  
  MqlTradeRequest request = {}; 
  request.action = TRADE_ACTION_DEAL;            
  request.magic = magic;                         
  request.comment = comment;
  request.symbol = _Symbol;                      
  request.volume = lotSize;                         
  request.sl = SL;                              
  request.tp = TP;                               
  request.type = ORDER_TYPE_BUY;
  request.price = Ask;                 
  request.deviation = slippage;
// Dynamically set the filling mode based on symbol's supported modes
  if ((SymbolInfoInteger (_Symbol, SYMBOL_FILLING_MODE) & SYMBOL_FILLING_FOK) != 0) request.type_filling = ORDER_FILLING_FOK;
  else if ((SymbolInfoInteger (_Symbol, SYMBOL_FILLING_MODE) & SYMBOL_FILLING_IOC) != 0) request.type_filling = ORDER_FILLING_IOC;
  else request.type_filling = ORDER_FILLING_RETURN;

  MqlTradeResult result = {0}; 

  for (int i = 0; i < 10; i++)
   {
    Ans = OrderSend (request,result);
     
    if (Ans) break;
    Sleep (500);
   }
  if (Ans) 
   {
    Print (_Symbol,": BUY order is opened. ");
   }
  else
   {
    string Err = IntegerToString (GetLastError());
    Print (_Symbol,": Error opening the BUY order: ", Err, ". Retcode: ", result.retcode);
   }
 }
 
//+------------------------------------------------------------------+

void openSell()
 {
  double SL;
  double TP;
  if (stopLoss == 0) SL = 0;
  else SL = Bid + stopLoss * _point;
  if (takeProfit == 0) TP = 0;
  else TP = Bid - takeProfit * _point;

  bool Ans = false;

  MqlTradeRequest request = {}; 
  request.action = TRADE_ACTION_DEAL;            
  request.magic = magic;                         
  request.comment = comment;
  request.symbol = _Symbol;                      
  request.volume = lotSize;                          
  request.sl = SL;                               
  request.tp = TP;                                 
  request.type = ORDER_TYPE_SELL;
  request.price = Bid;                  
  request.deviation = slippage;
// Dynamically set the filling mode based on symbol's supported modes
  if ((SymbolInfoInteger (_Symbol, SYMBOL_FILLING_MODE) & SYMBOL_FILLING_FOK) != 0) request.type_filling = ORDER_FILLING_FOK;
  else if ((SymbolInfoInteger (_Symbol, SYMBOL_FILLING_MODE) & SYMBOL_FILLING_IOC) != 0) request.type_filling = ORDER_FILLING_IOC;
  else request.type_filling = ORDER_FILLING_RETURN;

  MqlTradeResult result = {0}; 
   
  for (int i = 0; i < 10; i++)
   {
    Ans = OrderSend (request, result);
    
    if (Ans) break;
    Sleep (500);
   }
  if (Ans)
   {
    Print (_Symbol,": Sell order is opened. ");
   }
  else
   {
    string Err = IntegerToString (GetLastError());
    Print (_Symbol,": Error opening the Sell order: ", Err, ". Retcode: ", result.retcode);
   }
 }

//+------------------------------------------------------------------+

void calculateAskBid()
 {
  Ask = SymbolInfoDouble (_Symbol, SYMBOL_ASK);
  Bid = SymbolInfoDouble (_Symbol, SYMBOL_BID);
 }
 
//+------------------------------------------------------------------+
