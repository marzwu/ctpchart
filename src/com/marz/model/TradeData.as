package com.marz.model {
	import com.marz.utils;
	
	public class TradeData {
		public var t:Number;
		private var _t_str:String;
		public var side:int;
		public var isOpen:Boolean;
		public var price:Number;
		public var pos:int;
		
		public function TradeData() {
		}
		
		public function get t_str():String {
			return _t_str;
		}
		
		public function set t_str(value:String):void {
			value = utils.convertDateStr(value);
			_t_str = value;
			t = Date.parse(value);
			
//			var d:Date = new Date();
//			d.time = t;
//			trace(value, d);
		}
	}
}
