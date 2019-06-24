package {
	
	import com.bit101.components.ComboBox;
	import com.cangzhitao.menu.MenuUtil;
	import com.marz.KBox;
	import com.marz.model.DataFrame;
	import com.marz.model.KData;
	import com.marz.model.TradeData;
	
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
		
		private var com:ComboBox;
		private var kbox:KBox;
		
		private var menuXML:XML =
				<root>
					<menu label="文件(F)" data="file" mnemonicIndex="3">
						<!--item label="新建(N)" data="new" keyEquivalent="n" mnemonicIndex="3" selectFunction=""/-->
						<item label="打开历史数据" data="openHist" keyEquivalent="o" mnemonicIndex="3"
							  selectFunction="main.openHist"/>
						<item label="打开回测结果" data="openTrade" keyEquivalent="b" mnemonicIndex="3"
							  selectFunction="main.openTrade"/>
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
//			stage.addEventListener(Event.RESIZE, onResize);
//			stage.addEventListener(Event.ADDED, onActive);

//			this.addEventListener(Event.COMPLETE, onActive);
			
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
//			stage.nativeWindow.addEventListener(Event.ADDED_TO_STAGE, onActive);
//			NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, onActive);
//			trace(NativeApplication.nativeApplication.applicationDescriptor);
			
			
			kbox = new KBox();
//			kbox.setData(createTestData());
			addChild(kbox);

//			addChild(new PushButton(this, 100, 200, 'nice day'));

//			var window:Window = new Window();
//			window.title='hello window';
//			window.minimized=false;
//			addChild(window);

//			var vbox:VBox = new VBox();
//			vbox.width = 800;
//			vbox.height = 600;
//			addChild(vbox);
			
			com = new ComboBox(null, 0, 0, '', KBox.levels);
			com.selectedIndex = 0;
			com.addEventListener(Event.SELECT, onSelect);
			addChild(com);
			
			loader = new URLLoader();
			configureListeners(loader);
			
			var request:URLRequest = new URLRequest("http://www.baidu.com");
			try {
				loader.load(request);
			} catch (error:Error) {
				trace("Unable to load requested document.");
			}
		}
		
		private function onSelect(event:Event):void {
//			trace(event.type);
			var t:ComboBox = (ComboBox)(event.currentTarget);
			kbox.level = t.selectedIndex;
			kbox.show();
		}
		
		public function openHist(path:String):void {
//			var fileToOpen:File = File.documentsDirectory;
			var fileToOpen:File = new File('D:\\github\\vnpy-1.9.2\\examples\\CtaBacktesting');
			fileToOpen.browseForOpen('选择历史文件');
			fileToOpen.addEventListener(Event.SELECT, onHistFileSelected);
		}
		
		private function onHistFileSelected(e:Event):void {
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
			
			var path:String = e.currentTarget.nativePath.split("\\").join("/");
			var fileName:String = path.substr(path.lastIndexOf("/") + 1, path.length);
			var lastIndexOf:int = fileName.lastIndexOf('.');
			if (lastIndexOf > 0) {
				fileName = fileName.substr(0, lastIndexOf)
			}
			kbox.symbol = fileName;
			kbox.quotes = ks;
			kbox.show();
		}
		
		public function openTrade(path:String):void {
//			var fileToOpen:File = File.documentsDirectory;
			var fileToOpen:File = new File('D:\\github\\120.76.243.155\\moneymaker\\backtesting');
			fileToOpen.browseForOpen('选择历史文件');
			fileToOpen.addEventListener(Event.SELECT, onTradeFileSelected);
		}
		
		private function onTradeFileSelected(e:Event):void {
			trace(e.currentTarget.nativePath);
			
			var df:DataFrame = DataFrame.read_csv(e.currentTarget.nativePath);
			trace(df.data);
			trace(df.getRow(0));
			trace(df.size());
			
			var trades:Vector.<TradeData> = new Vector.<TradeData>();
			var size:uint = df.size();
			for (var i:int = 0; i < size; i++) {
				var t:TradeData = new TradeData();
				t.t_str = df.data['entryDt'][i];
				t.price = df.data['entryPrice'][i];
				t.pos = df.data['turnover'][i];
			}
			
			kbox.trades = trades;

//			kbox.setData(ks);
			kbox.show();
		}
		
		
		public function exitApp(errorCode:int = 0):void {
			NativeApplication.nativeApplication.exit();
		}
		
		
		private function onResize(e:Event):void {
			com.x = stage.stageWidth - com.width;
			kbox.show();
		}
		
		private function onEnterFrame(e:Event):void {
			stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			MenuUtil.classes["main"] = this;
			stage.nativeWindow.menu = MenuUtil.createRootMenu(menuXML);
			
			NativeApplication.nativeApplication.removeEventListener(Event.ACTIVATE, onEnterFrame);

//			var na:NativeApplication = NativeApplication(e.currentTarget);
			var na:NativeApplication = NativeApplication.nativeApplication;
//			na.addEventListener(NativeWindowBoundsEvent.RESIZE, onResize);
			na.activeWindow.addEventListener(NativeWindowBoundsEvent.RESIZE, onResize);
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
