/**
 *
 */
package away3d.materials.methods
{
	import com.instagal.regs.*;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;

	public class AnisotropicSpecularMethod extends BasicSpecularMethod
	{
		public function AnisotropicSpecularMethod()
		{
			super();
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsTangents = true;
			vo.needsView = true;
		}

		arcane override function getFragmentCodePerLight(vo : MethodVO, lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : ShaderChunk
		{
			var code : ShaderChunk = new ShaderChunk();
			var t : ShaderRegisterElement;

			if (lightIndex > 0) {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			else t = _totalLightColorReg;
			
			var tr : uint = t.value();
			// (sin(l,t) * sin(v,t) - cos(l,t)*cos(v,t)) ^ k

			code.nrm( tr ^ xyz, _tangentVaryingReg.value() ^ xyz );
			code.dp3( tr ^ w  , tr ^ xyz, lightDirReg.value() ^xyz ); 
			code.dp3( tr ^ z  , tr ^ xyz, _viewDirFragmentReg.value() ^xyz ); 
			code.sin( tr ^ x  , tr ^ w); 
			code.sin( tr ^ y  , tr ^ z); 
			code.mul( tr ^ x  , tr ^ x, tr ^y); 
			code.cos( tr ^ z  , tr ^ z); 
			code.cos( tr ^ w  , tr ^ w); 
			code.mul( tr ^ w  , tr ^ w, tr ^ z); 
			code.sub( tr ^ w  , tr ^ x, tr ^ w); 


			if (_useTexture) {
				// apply gloss modulation from texture
				code.mul( _specularTexData.value() ^w, _specularTexData.value() ^y, _specularDataRegister.value() ^w );
				code.pow( tr ^w, tr ^w, _specularTexData.value() ^w);
			}
			else
				code.pow( tr ^w, tr ^w, _specularDataRegister.value() ^w );

			// attenuate
			code.mul( tr ^w,  tr ^w, lightDirReg.value() ^w );

			if (_modulateMethod != null) _modulateMethod(code, vo, t, regCache);

			code.mul( tr ^xyz, lightColReg.value() ^xyz, tr ^w );

			if (lightIndex > 0) {
				code.add( _totalLightColorReg.value() ^xyz, _totalLightColorReg.value() ^xyz, tr^xyz );
				regCache.removeFragmentTempUsage(t);
			}

			return code;
		}
	}
}
