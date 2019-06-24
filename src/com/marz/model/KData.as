package com.marz.model {
	public class KData {
		public var t:Number;
		private var _t_str:String;
		public var o:Number;
		public var h:Number;
		public var l:Number;
		public var c:Number;
		
		public function KData(t:Number, o:Number, h:Number, l:Number, c:Number) {
			this.t = t;
			this.o = o;
			this.h = h;
			this.l = l;
			this.c = c;
		}
		
		public function get t_str():String {
			return _t_str;
		}
		
		public function set t_str(value:String):void {
			_t_str = value;
			t = Date.parse(value);
		}
	}
}
