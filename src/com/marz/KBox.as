package com.marz {
	import com.marz.model.KData;
	import com.marz.model.TradeData;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Keyboard;
	
	import mx.utils.StringUtil;
	
	public class KBox extends Sprite {
		public static const levels:Array = ['1min', '3min', '5min', '15min', '30min', '1h'];
		public static const levels_i:Array = [1, 3, 5, 15, 30, 60];
		
		private var bgLayer:Sprite;//背景层
		private var kLayer:Sprite;//柱体层
		private var incatorLayer:Sprite;//指标层
		private var crossStarLayer:Sprite;//十字星层
		private var infoLayer:TextField;//信息层
		private var floatPriceTxt:TextField;
		private var floatDateTimeTxt:TextField;
		
		private var _symbol:String = '';//数据名
		private var _quotesChanged:Boolean = false;
		private var _quotes:Array = [];//行情数据
		private var _quotesOnLevel:Array = [];//聚合后的行情
		private var _dataInBox:Array;//窗口内的行情
		private var _hValue:Number;
		private var _lValue:Number;
		
		private var _tradesChanged:Boolean = false;
		private var _trades:Vector.<TradeData> = new Vector.<TradeData>();//交易数据
		
		private var k_count_on_show:int = 10;//显示的k线根数
		private var k_cursor:int = 0;//显示的k线开始位置
		private var _levelChanged:Boolean = false;//k线级别是否被修改
		private var _level:int = 0;//k线级别 [1min, 3min, 5min]
		
		private var margin:int = 2;//留白，单位像素
		private var gap:int = 2;//k线间隔，单位像素
		private var k_width:int = 20;//k线宽度，单位像素
		private var k_width_max:int = 20;
		
		//k线最大宽度，单位像素
		
		
		public function KBox() {
			addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			addEventListener(Event.ADDED_TO_STAGE, onAddToStage);
			
			infoLayer = new TextField();
			infoLayer.mouseEnabled = false;
			infoLayer.mouseWheelEnabled = false;
			infoLayer.autoSize = TextFieldAutoSize.LEFT;
			infoLayer.text = '工商银行 o:0 h:0 l:0 c:0';
			addChild(infoLayer);
			
			kLayer = new Sprite();
			kLayer.mouseChildren = false;
			kLayer.mouseEnabled = false;
			addChild(kLayer);
			
			crossStarLayer = new Sprite();
			crossStarLayer.mouseChildren = false;
			crossStarLayer.mouseEnabled = false;
			addChild(crossStarLayer);
			
			floatPriceTxt = new TextField();
			floatPriceTxt.mouseEnabled = false;
			floatPriceTxt.mouseWheelEnabled = false;
			floatPriceTxt.autoSize = TextFieldAutoSize.LEFT;
			crossStarLayer.addChild(floatPriceTxt);
			
			floatDateTimeTxt = new TextField();
			floatDateTimeTxt.mouseEnabled = false;
			floatDateTimeTxt.mouseWheelEnabled = false;
			floatDateTimeTxt.autoSize = TextFieldAutoSize.LEFT;
			crossStarLayer.addChild(floatDateTimeTxt);
		}
		
		private function onAddToStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddToStage);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private function onKeyDown(e:KeyboardEvent):void {
			var direction:int = 0;
			var updown:int = 0;
			if (e.keyCode == Keyboard.LEFT)
				direction = -1;
			else if (e.keyCode == Keyboard.RIGHT)
				direction = 1;
			else if (e.keyCode == Keyboard.END) {
				direction = int.MAX_VALUE;
			} else if (e.keyCode == Keyboard.UP)
				updown = 1;
			else if (e.keyCode == Keyboard.DOWN)
				updown = -1;
			else
				return;
			
			var speed:int = e.ctrlKey ? 10 : 1;
			k_cursor += speed * direction;
			k_width += updown * 2;
			show();
		}
		
		private function onMouseWheel(e:MouseEvent):void {
			var direction:int = 0;
			var updown:int = e.delta;
			
			var speed:int = e.ctrlKey ? 10 : 1;
			k_cursor += speed * direction;
			k_width += updown * 2;
			show();
		}
		
		private function onMouseMove(e:MouseEvent):void {
			if (_dataInBox && _dataInBox.length > 0) {
				var windowWidth:int = stage.stageWidth - margin * 2;
				var windowHeight:int = stage.stageHeight - margin * 2;

//				crossStarLayer.x = crossStarLayer.y = margin;
				
				crossStarLayer.graphics.clear();
				crossStarLayer.graphics.lineStyle(1, 0xff00ff);
				
				//横线
				crossStarLayer.graphics.moveTo(margin, e.localY);
				crossStarLayer.graphics.lineTo(margin + windowWidth, e.localY);
				//竖线
				crossStarLayer.graphics.moveTo(e.localX, margin);
				crossStarLayer.graphics.lineTo(e.localX, margin + windowHeight);
				
				//y值
				var scale:Number = 1.0 * windowHeight / (_hValue - _lValue);
				floatPriceTxt.text = '' + (_hValue - (e.localY - margin) / scale).toFixed(2);
				floatPriceTxt.y = e.localY - floatPriceTxt.height;
				
				//ohlc
				var index:int = (e.localX - margin) / (k_width + gap);
				if (0 <= index && index < _dataInBox.length) {
					var k:KData = _dataInBox[index];
					var c:String = k.c > k.o ? '#ff0000' : '#0000ff';
					infoLayer.htmlText = StringUtil.substitute('{0} <font color="{5}">o:{1}, h:{2}, l:{3}, c:{4}</font>', symbol, k.o, k.h, k.l, k.c, c);
					
					//时间
					floatDateTimeTxt.text = '' + k.t_str;
					floatDateTimeTxt.x = e.localX;
					floatDateTimeTxt.y = margin + windowHeight - floatDateTimeTxt.height;
				}
			}
		}
		
		public function show():void {
			infoLayer.text = symbol;
			
			calcKData();
			drawBg();
			drawKline();
			drawTrade();
		}
		
		/**
		 * 根据k线周期，组织k线
		 */
		private function calcKData():void {
			if (_levelChanged || _quotesChanged || _tradesChanged) {
				_levelChanged = false;
				_quotesChanged = false;
				_tradesChanged = false;
				
				//组织新周期的K线
				var period:int = KBox.levels_i[_level];
				if (period == 1) {
					_quotesOnLevel = _quotes;
				} else {
					_quotesOnLevel = [];
					var len:uint = _quotes.length;
					for (var i:int = 0; i < len; i++) {
						var item:KData = _quotes[i];
						if (i % period == 0) {//周期内第一根K线
							var k:KData = new KData(item.t, item.o, item.h, item.l, item.c);
							k.t_str = item.t_str;
							_quotesOnLevel.push(k);
						} else {
							var k:KData = _quotesOnLevel[_quotesOnLevel.length - 1];
							k.h = Math.max(k.h, item.h);
							k.l = Math.min(k.l, item.l);
							k.c = item.c;
						}
					}
				}
				
				//附加交易信息
				for each(var trade:TradeData in _trades) {
					for each(var k:KData in _quotesOnLevel) {
						if (k.t <= trade.t && trade.t < k.t + period * 60 * 1000) {
							k.addTrade(trade);
							break;
						}
					}
				}
			}
		}
		
		private function drawTrade():void {
		
		}
		
		private function drawKline():void {
			kLayer.graphics.clear();
//			kLayer.x = margin;
//			kLayer.y = margin;

//			kLayer.graphics.lineStyle(1, 0xff0000);
//			if (NativeApplication.nativeApplication.activeWindow)
//				kLayer.graphics.drawRect(0, 0, NativeApplication.nativeApplication.activeWindow.width, NativeApplication.nativeApplication.activeWindow.height);
//			else
//				kLayer.graphics.drawRect(0, 0, stage.width, stage.height);
			var windowWidth:int = stage.stageWidth - margin * 2;
			var windowHeight:int = stage.stageHeight - margin * 2;
//			trace('windowWidth', windowWidth, 'windowHeight', windowHeight);
			
			k_width = Math.max(2, k_width);
			
			k_count_on_show = (windowWidth - margin * 2 - k_width) / (k_width + gap) + 1;
			
			k_cursor = Math.max(0, k_cursor);
			k_cursor = Math.min(_quotesOnLevel.length - 1, k_cursor);
			
			_dataInBox = _quotesOnLevel.slice(k_cursor, k_cursor + k_count_on_show);
			
			_hValue = int.MIN_VALUE;
			_lValue = int.MAX_VALUE;
			
			for each (var kd:KData in _dataInBox) {
				_hValue = Math.max(_hValue, kd.h);
				_lValue = Math.min(_lValue, kd.l);
			}
			
			
			var scale:Number = 1.0 * windowHeight / (_hValue - _lValue);
			
			for (var i:int = 0; i < _dataInBox.length; i++) {
				var k:KData = _dataInBox[i];
				var height:Number = -(k.c - k.o) * scale;
				var c:uint = k.c > k.o ? 0xff0000 : 0x0000ff;
				kLayer.graphics.lineStyle(1, c);
				//柱体
				kLayer.graphics.drawRect(margin + i * (gap + k_width), margin + (_hValue - k.o) * scale, k_width, height);
				//上影线
				kLayer.graphics.moveTo(margin + i * (gap + k_width) + .5 * k_width, margin + (_hValue - k.h) * scale);
				kLayer.graphics.lineTo(margin + i * (gap + k_width) + .5 * k_width, margin + (_hValue - Math.max(k.o, k.c)) * scale);
				//下影线
				kLayer.graphics.moveTo(margin + i * (gap + k_width) + .5 * k_width, margin + (_hValue - k.l) * scale);
				kLayer.graphics.lineTo(margin + i * (gap + k_width) + .5 * k_width, margin + (_hValue - Math.min(k.o, k.c)) * scale);
				
				
				if (k.trades) {
					for each(var trade:TradeData in k.trades) {
						if (trade.side == 1) {
							//多仓位置
							kLayer.graphics.lineStyle(1, 0xff0000);
							kLayer.graphics.beginFill(0xff0000, .8);
							kLayer.graphics.moveTo(margin + i * (gap + k_width) + .5 * k_width, margin + (_hValue - trade.price) * scale);
							kLayer.graphics.lineTo(margin + i * (gap + k_width), margin + (_hValue - trade.price) * scale + 10);
							kLayer.graphics.lineTo(margin + i * (gap + k_width) + 1 * k_width, margin + (_hValue - trade.price) * scale + 10);
							kLayer.graphics.lineTo(margin + i * (gap + k_width) + .5 * k_width, margin + (_hValue - trade.price) * scale);
							kLayer.graphics.endFill();
						} else {
							//空仓位置
							kLayer.graphics.lineStyle(1, 0x0000ff);
							kLayer.graphics.beginFill(0x0000ff, .8);
							kLayer.graphics.moveTo(margin + i * (gap + k_width) + .5 * k_width, margin + (_hValue - trade.price) * scale);
							kLayer.graphics.lineTo(margin + i * (gap + k_width), margin + (_hValue - trade.price) * scale - 10);
							kLayer.graphics.lineTo(margin + i * (gap + k_width) + 1 * k_width, margin + (_hValue - trade.price) * scale - 10);
							kLayer.graphics.lineTo(margin + i * (gap + k_width) + .5 * k_width, margin + (_hValue - trade.price) * scale);
							kLayer.graphics.endFill();
						}
						
					}
				}
			}
		}
		
		private function drawBg():void {
			this.graphics.clear();
			this.graphics.lineStyle(1, 0xffffff);
			this.graphics.beginFill(0xffffff, 1);
			this.graphics.drawRect(0, 0, stage.stageWidth - 1, stage.stageHeight - 1);
			this.graphics.endFill();
		}
		
		public function get symbol():String {
			return _symbol;
		}
		
		public function set symbol(value:String):void {
			_symbol = value;
		}
		
		public function get trades():Vector.<TradeData> {
			return _trades;
		}
		
		public function set trades(value:Vector.<TradeData>):void {
			if (_trades != value) {
				_trades = value;
				_tradesChanged = true;
			}
		}
		
		public function get quotes():Array {
			return _quotes;
		}
		
		public function set quotes(value:Array):void {
			if (_quotes != value) {
				_quotes = value;
				_quotesChanged = true;
			}
		}
		
		public function set level(level:int):void {
			if (_level != level) {
				_level = level;
				_levelChanged = true;
			}
		}
	}
}
