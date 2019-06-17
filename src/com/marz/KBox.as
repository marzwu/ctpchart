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
		private var bgLayer:Sprite;//背景层
		private var kLayer:Sprite;//柱体层
		private var incatorLayer:Sprite;//指标层
		private var crossStarLayer:Sprite;//十字星层
		private var infoLayer:TextField;//信息层
		private var floatPriceTxt:TextField;
		private var floatDateTimeTxt:TextField;
		
		private var _symbol:String = '';//数据名
		private var _quotes:Array = [];//所有数据
		private var _dataInBox:Array;
		private var _hValue:Number;
		private var _lValue:Number;
		
		private var _trades:Vector.<TradeData> = new Vector.<TradeData>();//交易数据
		
		private var k_count_on_show:int = 10;//显示的k线根数
		private var k_cursor:int = 0;//显示的k线开始位置
		
		private var margin:int = 2;//留白，单位像素
		private var gap:int = 2;//k线间隔，单位像素
		private var k_width:int = 20;//k线宽度，单位像素
		private var k_width_max:int = 20;//k线最大宽度，单位像素
		
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
			else if (e.keyCode == Keyboard.UP)
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
			
			drawBg();
			drawKline();
			drawTrade();
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
			k_cursor = Math.min(_quotes.length - 1, k_cursor);
			
			_dataInBox = _quotes.slice(k_cursor, k_cursor + k_count_on_show);
			
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
			_trades = value;
		}
		
		public function get quotes():Array {
			return _quotes;
		}
		
		public function set quotes(value:Array):void {
			_quotes = value;
		}
	}
}
