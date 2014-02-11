package away3d.materials.methods
{
	import com.instagal.regs.*;
	import com.instagal.Tex;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.lights.DirectionalLight;
	import away3d.lights.PointLight;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;

	public class TripleFilteredShadowMapMethod extends ShadowMapMethodBase
	{
		/**
		 * Creates a new BasicDiffuseMethod object.
		 *
		 * @param castingLight The light casting the shadow
		 */
		public function TripleFilteredShadowMapMethod(castingLight : DirectionalLight)
		{
			super(castingLight);
			if (castingLight is PointLight) throw new Error("FilteredShadowMapMethod not supported for Point Lights");
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			super.initConstants(vo);
			var fragmentData : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;

			fragmentData[index+8] = 1/3;
			fragmentData[index+9] = castingLight.shadowMapper.depthMapSize;
			fragmentData[index+10] = 1/castingLight.shadowMapper.depthMapSize;
		}

		/**
		 * @inheritDoc
		 */
		override protected function getPlanarFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk
		{
			var depthMapRegister : ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var customDataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var depthCol : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var uvReg : ShaderRegisterElement;
			var code : ShaderChunk = new ShaderChunk();
			vo.fragmentConstantsIndex = decReg.index*4;

			regCache.addFragmentTempUsages(depthCol, 1);

			uvReg = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(uvReg, 1);
			
			var uvr : uint = uvReg.value();
			var dcl : uint = depthCol.value();
			var tgr : uint = targetReg.value();
			var dcr : uint = _depthMapCoordReg.value();
			var vdf : uint = _viewDirFragmentReg.value();
			var dmr : uint = depthMapRegister.value();
			var drg : uint = customDataReg.value();
			var ddr : uint = dataReg.value();
			var dec : uint = decReg.value();
			
			var smp : uint = depthMapRegister.value() | Tex.NEAREST|Tex.CLAMP;

			code.mov(  uvr ,    dcr				);
			code.tex(  dcl ,    uvr ,    smp	);
			code.dp4(  dcl ^z,  dcl ,    dec	);
			code.sub(  dcl ^z,  dcl ^z,  ddr ^x	);
			code.slt(  uvr ^z,  dcr ^z,  dcl ^z	);
			code.add(  uvr ^x,  uvr ^x,  drg ^z	);
			code.tex(  dcl   ,  uvr ,    smp	);
			code.dp4(  dcl ^z,  dcl ,    dec 	);
			code.sub(  dcl ^z,  dcl ^z,  ddr ^x	);
			code.slt(  uvr ^w,  dcr ^z,  dcl ^z	);
			code.div(  dcl ^x,  dcr ^x,  drg ^z	);
			code.frc(  dcl ^x,  dcl ^x			);
			code.sub(  uvr ^w,  uvr ^w,  uvr ^z	);
			code.mul(  uvr ^w,  uvr ^w,  dcl ^x	);
			code.add(  vdf ^w,  uvr ^z,  uvr ^w	);
			code.sub(  uvr ^x,  dcr ^x,  drg ^z	);
			code.add(  uvr ^y,  dcr ^y,  drg ^z	);
			code.tex(  dcl ,    uvr ,    smp	);
			code.dp4(  dcl ^z,  dcl ,    dec    );
			code.sub(  dcl ^z,  dcl ^z,  ddr ^x	);
			code.slt(  uvr ^z,  dcr ^z,  dcl ^z	);
			code.add(  uvr ^x,  uvr ^x,  drg ^z	);
			code.tex(  dcl ,    uvr ,    smp    );
			code.dp4(  dcl ^z,  dcl ,    dec    );
			code.sub(  dcl ^z,  dcl ^z,  ddr ^x	);
			code.slt(  uvr ^w,  dcr ^z,  dcl ^z	);
			code.mul(  dcl ^x,  dcr ^x,  drg ^y	);
			code.frc(  dcl ^x,  dcl ^x			);
			code.sub(  uvr ^w,  uvr ^w,  uvr ^z	);
			code.mul(  uvr ^w,  uvr ^w,  dcl ^x	);
			code.add(  uvr ^w,  uvr ^z,  uvr ^w	);
			code.mul(  dcl ^x,  dcr ^y,  drg ^y	);
			code.frc(  dcl ^x,  dcl ^x			);
			code.sub(  uvr ^w,  uvr ^w,  vdf ^w	);
			code.mul(  uvr ^w,  uvr ^w,  dcl ^x	);
			code.add(  tgr ^w,  vdf ^w,  uvr ^w	);
			code.sub(  uvr ^xy, dcr ^xy, drg ^z	);
			code.tex(  dcl ,    uvr ,    smp    );
			code.dp4(  dcl ^z,  dcl ,    dec    );
			code.sub(  dcl ^z,  dcl ^z,  ddr ^x	);
			code.slt(  uvr ^z,  dcr ^z,  dcl ^z	);
			code.add(  uvr ^x,  uvr ^x,  drg ^z	);
			code.tex(  dcl ,    uvr ,    smp    );
			code.dp4(  dcl ^z,  dcl ,    dec    );
			code.sub(  dcl ^z,  dcl ^z,  ddr ^x	);
			code.slt(  uvr ^w,  dcr ^z,  dcl ^z	);
			code.div(  dcl ^x,  dcr ^x,  drg ^z	);
			code.frc(  dcl ^x,  dcl ^x			);
			code.sub(  uvr ^w,  uvr ^w,  uvr ^z	);
			code.mul(  uvr ^w,  uvr ^w,  dcl ^x	);
			code.add(  vdf ^w,  uvr ^z,  uvr ^w	);
			code.mov(  uvr ^x,  dcr ^x			);
			code.add(  uvr ^y,  uvr ^y,  drg ^z	);
			code.tex(  dcl ,    uvr ,    smp    );
			code.dp4(  dcl ^z,  dcl ,    dec    );
			code.sub(  dcl ^z,  dcl ^z,  ddr ^x	);
			code.slt(  uvr ^z,  dcr ^z,  dcl ^z	);
			code.add(  uvr ^x,  uvr ^x,  drg ^z	);
			code.tex(  dcl ,    uvr ,    smp    );
			code.dp4(  dcl ^z,  dcl ,    dec    );
			code.sub(  dcl ^z,  dcl ^z,  ddr ^x	);
			code.slt(  uvr ^w,  dcr ^z,  dcl ^z	);
			code.mul(  dcl ^x,  dcr ^x,  drg ^y	);
			code.frc(  dcl ^x,  dcl ^x			);
			code.sub(  uvr ^w,  uvr ^w,  uvr ^z	);
			code.mul(  uvr ^w,  uvr ^w,  dcl ^x	);
			code.add(  uvr ^w,  uvr ^z,  uvr ^w	);
			code.mul(  dcl ^x,  dcr ^y,  drg ^y	);
			code.frc(  dcl ^x,  dcl ^x			);
			code.sub(  uvr ^w,  uvr ^w,  vdf ^w	);
			code.mul(  uvr ^w,  uvr ^w,  dcl ^x	);
			code.add(  vdf ^w,  vdf ^w,  uvr ^w	);
			code.add(  tgr ^w,  tgr ^w,  vdf ^w	);
			code.add(  uvr ^xy, dcr ^xy, drg ^z	);
			code.tex(  dcl ,    uvr ,    smp    );
			code.dp4(  dcl ^z,  dcl ,    dec    );
			code.sub(  dcl ^z,  dcl ^z,  ddr ^x	);
			code.slt(  uvr ^z,  dcr ^z,  dcl ^z	);
			code.add(  uvr ^x,  uvr ^x,  drg ^z	);
			code.tex(  dcl ,    uvr ,    smp    );
			code.dp4(  dcl ^z,  dcl ,    dec    );
			code.sub(  dcl ^z,  dcl ^z,  ddr ^x	);
			code.slt(  uvr ^w,  dcr ^z,  dcl ^z	);
			code.div(  dcl ^x,  dcr ^x,  drg ^z	);
			code.frc(  dcl ^x,  dcl ^x			);
			code.sub(  uvr ^w,  uvr ^w,  uvr ^z	);
			code.mul(  uvr ^w,  uvr ^w,  dcl ^x	);
			code.add(  vdf ^w,  uvr ^z,  uvr ^w	);
			code.add(  uvr ^xy, dcr ^xy, drg ^z	);
			code.tex(  dcl ,    uvr ,    smp    );
			code.dp4(  dcl ^z,  dcl ,    dec    );
			code.sub(  dcl ^z,  dcl ^z,  ddr ^x	);
			code.slt(  uvr ^z,  dcr ^z,  dcl ^z	);
			code.add(  uvr ^x,  uvr ^x,  drg ^z	);
			code.tex(  dcl ,    uvr ,    smp    );
			code.dp4(  dcl ^z,  dcl ,    dec 	);
			code.sub(  dcl ^z,  dcl ^z,  ddr ^x	);
			code.slt(  uvr ^w,  dcr ^z,  dcl ^z	);
			code.mul(  dcl ^x,  dcr ^x,  drg ^y	);
			code.frc(  dcl ^x,  dcl ^x			);
			code.sub(  uvr ^w,  uvr ^w,  uvr ^z	);
			code.mul(  uvr ^w,  uvr ^w,  dcl ^x	);
			code.add(  uvr ^w,  uvr ^z,  uvr ^w	);
			code.mul(  dcl ^x,  dcr ^y,  drg ^y	);
			code.frc(  dcl ^x,  dcl ^x			);
			code.sub(  uvr ^w,  uvr ^w,  vdf ^w	);
			code.mul(  uvr ^w,  uvr ^w,  dcl ^x	);
			code.add(  vdf ^w,  vdf ^w,  uvr ^w	);
			code.add(  tgr ^w,  tgr ^w,  vdf ^w	);
			code.mul(  tgr ^w,  tgr ^w,  drg ^x	);


			regCache.removeFragmentTempUsage(depthCol);
			regCache.removeFragmentTempUsage(uvReg);

			vo.texturesIndex = depthMapRegister.index;

			return code;
		}

	}
}