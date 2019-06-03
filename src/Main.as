package {
	
	import com.bit101.components.VBox;
	import com.cangzhitao.menu.MenuUtil;
	import com.marz.KBox;
	import com.marz.KData;
	
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class Main extends Sprite {
		private var loader:URLLoader;
		
		private var kbox:KBox;
		
		private var menuXML:XML =
				<root>
					<menu label="文件(F)" data="file" mnemonicIndex="3">
						<!--item label="新建(N)" data="new" keyEquivalent="n" mnemonicIndex="3" selectFunction=""/-->
						<item label="打开历史数据" data="openHist" keyEquivalent="o" mnemonicIndex="3"
							  selectFunction="main.openHist"/>
						<item label="打开回测结果" data="openBacktest" keyEquivalent="b" mnemonicIndex="3"
							  selectFunction="main.openBacktest"/>
						<!--item label="保存(S)" data="save" keyEquivalent="s" mnemonicIndex="3" selectFunction=""/-->
						<!--item label="另存为(A)" data="save_as" keyEquivalent="S" mnemonicIndex="4" selectFunction=""/-->
						<item lable="separator"/>
						<item label="退出(X)" data="exit" keyEquivalent="x" mnemonicIndex="3"
							  selectFunction="main.exitApp"/>
					</menu>
					<menu label="帮助(H)" data="help" mnemonicIndex="3">
						<item label="关于" data="about" keyEquivalent="h" selectFunction=""/>
					</menu>
				</root>;
		
		public function Main() {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
//			stage.color=0x808080;
			stage.addEventListener(Event.RESIZE, onResize);
//			stage.addEventListener(Event.ADDED, onActive);

//			this.addEventListener(Event.COMPLETE, onActive);
			
			stage.addEventListener(Event.ENTER_FRAME, onActive);
//			stage.nativeWindow.addEventListener(Event.ADDED_TO_STAGE, onActive);
//			NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, onActive);
//			trace(NativeApplication.nativeApplication.applicationDescriptor);
			
			
			kbox = new KBox();
			kbox.setData(createTestData());
			addChild(kbox);

//			addChild(new PushButton(this, 100, 200, 'nice day'));

//			var window:Window = new Window();
//			window.title='hello window';
//			window.minimized=false;
//			addChild(window);
			
			var vbox:VBox = new VBox();
			vbox.width = 800;
			vbox.height = 600;
			addChild(vbox);
			
			loader = new URLLoader();
			configureListeners(loader);
			
			var request:URLRequest = new URLRequest("http://www.baidu.com");
			try {
				loader.load(request);
			} catch (error:Error) {
				trace("Unable to load requested document.");
			}
		}
		
		public function openHist(path:String):void {
			var fileToOpen:File = File.documentsDirectory;
			fileToOpen.browseForOpen('选择历史文件');
			fileToOpen.addEventListener(Event.SELECT, fileSelected);
		}
		
		private function fileSelected(e:Event):void {
			trace(e.currentTarget.nativePath);
			
			var stream:FileStream = new FileStream();
			var file:File = new File(e.currentTarget.nativePath);//绑定一个文件
			stream.open(file, FileMode.READ);//读取文件
			var str:String = stream.readMultiByte(stream.bytesAvailable, 'utf-8');
			stream.close();
			
			var items:Array = str.split('\n');
			items = items.slice(1, items.length - 1);
			var ks:Array = [];
			for each(var item:String in items) {
				var values:Array = item.split(',');
//				trace(values);
				if (values.length >= 5) {
					var k:KData = new KData(null, parseFloat(values[1]), parseFloat(values[2]), parseFloat(values[3]), parseFloat(values[4]));
					k.t_str = values[0];
					ks.push(k);
				}
			}
			kbox.setData(ks);
			kbox.show();

//			trace(NativeApplication.nativeApplication.activeWindow.bounds);
//			trace(NativeApplication.nativeApplication.activeWindow.listOwnedWindows().length);
//			trace(stage.width,stage.height);
			trace(stage.stageWidth, stage.stageHeight);
		}
		
		public function openBacktest(path:String):void {
			var stream:FileStream = new FileStream();
			var file:File = new File(path);//绑定一个文件
			stream.open(file, FileMode.READ);//读取文件
			trace(stream.readMultiByte(stream.bytesAvailable, 'utf-8'));
			stream.close();
		}
		
		public function exitApp(errorCode:int = 0):void {
			NativeApplication.nativeApplication.exit();
		}
		
		private function createTestData():Array {
			var r:Array = [];
			r.push(new KData(new Date(), 1, 3, 1, 2));
			r.push(new KData(new Date(), 2, 3, 2, 3));
			r.push(new KData(new Date(), 3, 3, 2, 2));
			r.push(new KData(new Date(), 2, 2, 1, 1));
			return r;
		}
		
		private function onResize(e:Event):void {
			
			
			kbox.show();
		}
		
		private function onActive(e:Event):void {
			stage.removeEventListener(Event.ENTER_FRAME, onActive);
			
			
			MenuUtil.classes["main"] = this;
			stage.nativeWindow.menu = MenuUtil.createRootMenu(menuXML);
			
			NativeApplication.nativeApplication.removeEventListener(Event.ACTIVATE, onActive);

//			var na:NativeApplication = NativeApplication(e.currentTarget);
			var na:NativeApplication = NativeApplication.nativeApplication;
			na.addEventListener(NativeWindowBoundsEvent.RESIZE, onResize);
			na.activeWindow.title = "复盘神器";
			na.activeWindow.maximize();
		}
		
		
		private function configureListeners(dispatcher:IEventDispatcher):void {
			dispatcher.addEventListener(Event.COMPLETE, completeHandler);
			dispatcher.addEventListener(Event.OPEN, openHandler);
			dispatcher.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}
		
		private function completeHandler(event:Event):void {
			var loader:URLLoader = URLLoader(event.target);
//			trace("completeHandler: " + loader.data);
		}
		
		private function openHandler(event:Event):void {
			trace("openHandler: " + event);
		}
		
		private function progressHandler(event:ProgressEvent):void {
			trace("progressHandler loaded:" + event.bytesLoaded + " total: " + event.bytesTotal);
		}
		
		private function securityErrorHandler(event:SecurityErrorEvent):void {
			trace("securityErrorHandler: " + event);
		}
		
		private function httpStatusHandler(event:HTTPStatusEvent):void {
			trace("httpStatusHandler: " + event);
		}
		
		private function ioErrorHandler(event:IOErrorEvent):void {
			trace("ioErrorHandler: " + event);
		}
	}
}
