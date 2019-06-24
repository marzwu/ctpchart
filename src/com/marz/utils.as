package com.marz {
	public class utils {
		/**
		 * dateStr格式必须为：yyyy-mm-dd HH:MM:SS，如：2013-8-7 9:30:15；
		 * <listing>
		 * <font size='2'>
		 * //e.g:
		 * var dateStr:String = "2013-8-7 9:30:15";
		 * var date:Date = new Date();
		 * date.time = Date.parse(convertDateStr(dateStr));
		 * //trace : Wed Aug 7 09:30:15 GMT+0800 2013
		 * trace(date.toString());
		 * </font>
		 * </listing>
		 * @author jave.lin
		 * @date 2013-8-7
		 * */
		public static function convertDateStr(dateStr:String):String {
			var strArr:Array = dateStr.split(" ");
//			var fStr:String = "{0} {1} {2}";
			var fStr:String = "{0} {1}";
			return format(fStr, (strArr[0] as String).split("-").join("/"), strArr[1], "GMT");
		}
		
		/**以前的format文章中的方法*/
		public static function format(str:String, ...args):String {
			for (var i:int = 0; i < args.length; i++) {
				str = str.replace(new RegExp("\\{" + i + "\\}", "gm"), args[i]);
			}
			return str;
		}
		
	}
}
