package com.marz.model {
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.Dictionary;
	
	public class DataFrame {
		public var data:Dictionary;//<head, column>
		
		public function DataFrame() {
			data = new Dictionary(true);
		}
		
		public function getRow(index:int):Object {
			var r:Object = {};
			for (var key:String in data) {
				r[key] = data[key][index];
			}
			return r;
		}
		
		public function size():uint {
			for each(var d:Array in data) {
				return d.length;
			}
			return 0;
		}
		
		/**
		 * csv文件第一行必须是列名
		 * @param path
		 * @return
		 */
		public static function read_csv(path:String):DataFrame {
			var stream:FileStream = new FileStream();
			var file:File = new File(path);//绑定一个文件
			stream.open(file, FileMode.READ);//读取文件
			var str:String = stream.readMultiByte(stream.bytesAvailable, 'utf-8');
			stream.close();
			
			var df:DataFrame = new DataFrame();
			var items:Array = str.split('\n');
			
			//读列头
			var head:Array = items[0].split(',');
			var dataArray:Array = [];
			for each(var h:String in head) {
				var column:Array = [];
				df.data[h] = column;
				dataArray.push(column);
			}
			
			//读取行
			items = items.slice(1, items.length - 1);
			for each(var item:String in items) {
				var values:Array = item.split(',');
				for (var i:int = 0; i < dataArray.length; i++) {
					dataArray[i].push(values[i]);
				}
			}
			
			return df;
		}
	}
}
