package away3d.materials.methods
{
	import com.instagal.Tex;
	import com.instagal.regs.*;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.lights.DirectionalLight;
	import away3d.materials.methods.MethodVO;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.BitmapTexture;

	import flash.display.BitmapData;

	use namespace arcane;

	public class DitheredShadowMapMethod extends ShadowMapMethodBase
	{
		private static var _grainTexture : BitmapTexture;
		private static var _grainUsages : int;
		private static var _grainBitmapData : BitmapData;
		private var _highRes : Boolean;
		private var _depthMapSize : int;
		private var _range : Number = 1;

		/**
		 * Creates a new DitheredShadowMapMethod object.
		 */
		public function DitheredShadowMapMethod(castingLight : DirectionalLight, highRes : Boolean = false)
		{
			// todo: implement for point lights
			super(castingLight);

			// area to sample in texture space
			_depthMapSize = castingLight.shadowMapper.depthMapSize;

			_highRes = highRes;

			++_grainUsages;

			if (!_grainTexture) {
				initGrainTexture();
			}
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			super.initConstants(vo);

			var fragmentData : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;
			fragmentData[index + 8] = _highRes? 1/8 : 1/4;
			fragmentData[index + 9] = _range/_depthMapSize;
			fragmentData[index + 10] = .5;
		}

		public function get range() : Number
		{
			return _range;
		}

		public function set range(value : Number) : void
		{
			_range = value;
		}

		private function initGrainTexture() : void
		{
			_grainBitmapData = new BitmapData(64, 64, false);
			var vec : Vector.<uint> = new Vector.<uint>();
			var len : uint = 4096;
			var step : Number = 1/(_depthMapSize*_range);
			var inv : Number = 1-step;
			var r : Number,  g : Number;

			for (var i : uint = 0; i < len; ++i) {
				r = 2*(Math.random() - .5)*inv;
				g = 2*(Math.random() - .5)*inv;
				if (r < 0) r -= step;
				else r += step;
				if (g < 0) g -= step;
				else g += step;

				vec[i] = (((r*.5 + .5)*0xff) << 16) | (((g*.5 + .5)*0xff) << 8);
			}

			_grainBitmapData.setVector(_grainBitmapData.rect, vec);
			_grainTexture = new BitmapTexture(_grainBitmapData);
		}

		override public function dispose() : void
		{
			if (--_grainUsages == 0) {
				_grainTexture.dispose();
				_grainBitmapData.dispose();
				_grainTexture = null;
			}
		}

		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			super.activate(vo,  stage3DProxy);
			vo.fragmentData[vo.fragmentConstantsIndex+9] = _range/_depthMapSize;
            stage3DProxy.setTextureAt(vo.texturesIndex+1, _grainTexture.getTextureForStage3D(stage3DProxy));
		}

		/**
		 * @inheritDoc
		 */
		override protected function getPlanarFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk
		{
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var grainRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var customDataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var uvReg : ShaderRegisterElement;
			var code : ShaderChunk = new ShaderChunk();
			
			var uvr : uint = uvReg.value();
			var dcl : uint = depthCol.value();
			var tgr : uint = targetReg.value();
			var dcr : uint = _depthMapCoordReg.value();
			var dmr : uint = depthMapRegister.value();

			vo.fragmentConstantsIndex = decReg.index*4;

			regCache.addFragmentTempUsages(depthCol, 1);

			uvReg = regCache.getFreeFragmentVectorTemp();

			
			code.div( uvr			, dcr 		,  customDataReg.value() ^y );
			code.tex( uvr			, uvr 		,  grainRegister.value() | Tex.NEAREST| Tex.REPEAT| Tex.MIPNONE);
			code.sub( uvr	^xy		, uvr ^xy	,  customDataReg.value() ^z ); 	// uv-.5
			code.add( uvr	^xy		, uvr ^xy	,  uvr ^xy );      // 2*(uv-.5)
			code.mul( uvr	^xy		, uvr ^xy	,  customDataReg.value()^y);
			code.add( uvr	^z		, dcr ^z	,  dataReg.value()^x);     // offset by epsilon
			code.add( uvr	^xy		, uvr ^xy	,  dcr^xy);
			code.tex( dcl			, uvr 		,  dmr | Tex.NEAREST| Tex.CLAMP | Tex.MIPNONE );
			code.dp4( dcl	^z		, dcl 		,  decReg.value() );
			code.slt( tgr	^w		, uvr ^z	,  dcl^z);    // 0 if in shadow
			code.sub( uvr	^xy		, uvr ^xy	,  dcr^xy);
			code.neg( uvr	^xy		, uvr ^xy	);
			code.add( uvr	^xy		, uvr ^xy	,  dcr^xy);
			code.tex( dcl			, uvr 		,  dmr | Tex.NEAREST| Tex.CLAMP | Tex.MIPNONE );
			code.dp4( dcl	^z		, dcl 		,  decReg.value() );
			code.slt( uvr	^w		, uvr ^z	,  dcl^z);    // 0 if in shadow
			code.add( tgr	^w		, tgr ^w	,  uvr^w);
			code.sub( uvr	^xy		, uvr ^xy	,  dcr^xy);
			code.mov( uvr	^xy		, uvr ^yx	);
			code.neg( uvr	^x		, uvr ^x	);
			code.add( uvr	^xy		, uvr ^xy	,  dcr^xy);
			code.tex( dcl			, uvr 		,  dmr | Tex.NEAREST| Tex.CLAMP | Tex.MIPNONE );
			code.dp4( dcl	^z		, dcl 		,  decReg.value()  );
			code.slt( uvr	^w		, uvr ^z	,  dcl^z);    // 0 if in shadow
			code.add( tgr	^w		, tgr ^w	,  uvr^w);
			code.sub( uvr	^xy		, uvr ^xy	,  dcr^xy);
			code.neg( uvr	^xy		, uvr ^xy	);
			code.add( uvr	^xy		, uvr ^xy	,  dcr^xy);
			code.tex( dcl			, uvr 		,  dmr | Tex.NEAREST| Tex.CLAMP | Tex.MIPNONE );
			code.dp4( dcl	^z		, dcl 		,  decReg.value() );
			code.slt( uvr	^w		, uvr ^z	,  dcl^z);    // 0 if in shadow
			code.add( tgr	^w		, tgr ^w	,  uvr^w);

			if (_highRes) {
					// reseed
				code.div( uvr ^xy	, dcr ^xy	, customDataReg.value() ^y);
				code.tex( uvr 		, uvr 		, grainRegister.value() | Tex.NEAREST| Tex.REPEAT| Tex.MIPNONE);
				code.sub( uvr ^xy	, uvr ^xy	, customDataReg.value() ^z);
				code.add( uvr ^xy	, uvr ^xy	, uvr ^xy);
				code.mul( uvr ^xy	, uvr ^xy	, customDataReg.value() ^y);
				code.add( uvr ^z	, dcr ^z	, dataReg.value()^x);     // offset by epsilon
				code.add( uvr ^xy	, uvr ^xy	, dcr^xy);
				code.tex( dcl 		, uvr 		, dmr | Tex.NEAREST| Tex.CLAMP | Tex.MIPNONE );
				code.dp4( dcl ^z	, dcl 		, decReg.value() );
				code.slt( uvr ^w	, uvr ^z	, dcl^z);    // 0 if in shadow
				code.add( tgr ^w	, tgr ^w	, uvr^w);
				code.sub( uvr ^xy	, uvr ^xy	, dcr^xy);
				code.neg( uvr ^xy	, uvr ^xy);
				code.add( uvr ^xy	, uvr ^xy	, dcr^xy);
				code.tex( dcl 		, uvr 		, dmr | Tex.NEAREST| Tex.CLAMP | Tex.MIPNONE );
				code.dp4( dcl ^z	, dcl 		, decReg.value() );
				code.slt( uvr ^w	, uvr ^z	, dcl^z);    // 0 if in shadow
				code.add( tgr ^w	, tgr ^w	, uvr^w);
				code.sub( uvr ^xy	, uvr ^xy	, dcr^xy);
				code.mov( uvr ^xy	, uvr ^yx);
				code.neg( uvr ^x	, uvr ^x);
				code.add( uvr ^xy	, uvr ^xy	, dcr^xy);
				code.tex( dcl 		, uvr 		, dmr | Tex.NEAREST| Tex.CLAMP | Tex.MIPNONE );
				code.dp4( dcl ^z	, dcl 		, decReg.value() );
				code.slt( uvr ^w	, uvr ^z	, dcl^z);    // 0 if in shadow
				code.add( tgr ^w	, tgr ^w	, uvr^w);
				code.sub( uvr ^xy	, uvr ^xy	, dcr^xy);
				code.neg( uvr ^xy	, uvr ^xy);
				code.add( uvr ^xy	, uvr ^xy	, dcr^xy);
				code.tex( dcl 		, uvr 		, dmr | Tex.NEAREST| Tex.CLAMP | Tex.MIPNONE );
				code.dp4( dcl ^z	, dcl 		, decReg.value() );
				code.slt( uvr ^w	, uvr ^z	, dcl^z);    // 0 if in shadow
				code.add( tgr ^w	, tgr ^w	, uvr^w);
			}

			regCache.removeFragmentTempUsage(depthCol);

			code.mul( tgr^w, tgr^w, customDataReg.value()^x);  // average

			vo.texturesIndex = depthMapRegister.index;

			return code;
		}
	}
}