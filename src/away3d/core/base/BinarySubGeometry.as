package away3d.core.base {

	import away3d.arcane;
	import away3d.bounds.BoundingBox;

	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	
	use namespace arcane;

	/**
	 * @author Pierre Lepers
	 * away3d.core.base.BinarySubGeom
	 */
	public class BinarySubGeometry extends SubGeometry {

		protected var _customData : ByteArray;
		protected var _vertices : ByteArray;
		protected var _colors : ByteArray;
		protected var _uvs : ByteArray;
		protected var _secondaryUvs : ByteArray;
		protected var _vertexNormals : ByteArray;
		protected var _vertexTangents : ByteArray;
		protected var _indices : ByteArray;
		protected var _faceNormalsData : ByteArray;
		protected var _faceWeights : ByteArray;
		protected var _faceTangents : ByteArray;

		protected var _customDataOffset : int;
		protected var _verticesOffset : int;
		protected var _colorsOffset : int;
		protected var _uvsOffset : int;
		protected var _secondaryUvsOffset : int;
		protected var _vertexNormalsOffset : int;
		protected var _vertexTangentsOffset : int;
		protected var _indicesOffset : int;

		protected var _bounds : BoundingBox;
		
		

		public function BinarySubGeometry() {
			super();
			_autoDeriveVertexNormals = false;
			_autoDeriveVertexTangents = false;
		}

		private function _updateBound() : void {
			
			_bounds = new BoundingBox();
			
			var lenV : uint;
			var i : uint;
			var v : Number;
			
			var minX : Number;
			var minY : Number;
			var minZ : Number;
			var maxX : Number;
			var maxY : Number;
			var maxZ : Number;
			

			lenV = _numVertices;
			_vertices.position = _verticesOffset;

			minX = 
			maxX = _vertices.readFloat();
			minY = 
			maxY = _vertices.readFloat();
			minZ = 
			maxZ = _vertices.readFloat();

			i = 1;
			while ( lenV > i++ ) {
				v = _vertices.readFloat();
				if ( v < minX ) minX = v;
				else if ( v > maxX ) maxX = v;
				v = _vertices.readFloat();
				if ( v < minY ) minY = v;
				else if ( v > maxY ) maxY = v;
				v = _vertices.readFloat();
				if ( v < minZ ) minZ = v;
				else if ( v > maxZ ) maxZ = v;
			}

			_bounds.minX = minX;
			_bounds.minY = minY;
			_bounds.minZ = minZ;
			_bounds.maxX = maxX;
			_bounds.maxY = maxY;
			_bounds.maxZ = maxZ;
		}


		override public function contributeBounds(bb : BoundingBox) : void {
			// TODO BinarySubGeometry bounds use invalidation system ?
			if( _bounds == null ) 
				_updateBound();

			bb.minX = Math.min( bb.minX, _bounds.minX );
			bb.minY = Math.min( bb.minY, _bounds.minY );
			bb.minZ = Math.min( bb.minZ, _bounds.minZ );
			bb.maxX = Math.max( bb.maxX, _bounds.maxX ); 
			bb.maxY = Math.max( bb.maxY, _bounds.maxY ); 
			bb.maxZ = Math.max( bb.maxZ, _bounds.maxZ ); 
		}

		override protected function _uploadCustom(customBuffer : VertexBuffer3D) : void {
			customBuffer.uploadFromByteArray(_customData, _customDataOffset, 0, _numVertices);
		}

		override protected function _uploadVertex(vertexBuffer : VertexBuffer3D) : void {
			vertexBuffer.uploadFromByteArray(_vertices, _verticesOffset, 0, _numVertices);
		}

		override protected function _uploadColor(colorBuffer : VertexBuffer3D) : void {
			colorBuffer.uploadFromByteArray(_colors, _colorsOffset, 0, _numVertices);
		}

		override protected function _uploadUv(uvBuffer : VertexBuffer3D) : void {
			uvBuffer.uploadFromByteArray(_uvs, _uvsOffset, 0, _numVertices);
		}

		override protected function _uploadSecondaryUv(secondaryUvBuffer : VertexBuffer3D) : void {
			secondaryUvBuffer.uploadFromByteArray(_secondaryUvs, _secondaryUvsOffset, 0, _numVertices);
		}

		override protected function _uploadVertexNormal(vertexNormalBuffer : VertexBuffer3D) : void {
			vertexNormalBuffer.uploadFromByteArray(_vertexNormals, _vertexNormalsOffset, 0, _numVertices);
		}

		override protected function _uploadVertexTangent(vertexTangentBuffer : VertexBuffer3D) : void {
			vertexTangentBuffer.uploadFromByteArray(_vertexTangents, _vertexTangentsOffset, 0, _numVertices);
		}

		override protected function _uploadIndex(indexBuffer : IndexBuffer3D) : void {
			indexBuffer.uploadFromByteArray(_indices, _indicesOffset, 0, _numIndices);
		}

		override public function applyTransformation(transform : Matrix3D) : void {
			var len : uint = _vertices.length / 3;
			var i : uint, i0 : uint, i1 : uint, i2 : uint;
			var v3 : Vector3D = new Vector3D();

			var bakeNormals : Boolean = _vertexNormals != null;
			var bakeTangents : Boolean = _vertexTangents != null;

			for (i = 0; i < len; ++i) {
				i0 = 3 * i;
				i1 = i0 + 1;
				i2 = i0 + 2;

				// bake position
				v3.x = _vertices[i0];
				v3.y = _vertices[i1];
				v3.z = _vertices[i2];
				v3 = transform.transformVector(v3);
				_vertices[i0] = v3.x;
				_vertices[i1] = v3.y;
				_vertices[i2] = v3.z;

				// bake normal
				if (bakeNormals) {
					v3.x = _vertexNormals[i0];
					v3.y = _vertexNormals[i1];
					v3.z = _vertexNormals[i2];
					v3 = transform.deltaTransformVector(v3);
					_vertexNormals[i0] = v3.x;
					_vertexNormals[i1] = v3.y;
					_vertexNormals[i2] = v3.z;
				}

				// bake tangent
				if (bakeTangents) {
					v3.x = _vertexTangents[i0];
					v3.y = _vertexTangents[i1];
					v3.z = _vertexTangents[i2];
					v3 = transform.deltaTransformVector(v3);
					_vertexTangents[i0] = v3.x;
					_vertexTangents[i1] = v3.y;
					_vertexTangents[i2] = v3.z;
				}
			}
		}

		override public function clone() : SubGeometry {
			var clone : BinarySubGeometry = new BinarySubGeometry();
			clone.updateVertexData( copyBytes(_vertices) );
			clone.updateUVData(copyBytes(_uvs));
			clone.updateIndexData(copyBytes(_indices));
			if (_secondaryUvs) clone.updateSecondaryUVData(copyBytes(_secondaryUvs));
			if (!_autoDeriveVertexNormals) clone.updateVertexNormalData(copyBytes(_vertexNormals));
			if (!_autoDeriveVertexTangents) clone.updateVertexTangentData(copyBytes(_vertexTangents));
			return clone;
		}
		
		override public function scale(scale : Number):void
		{
			var len : uint = _vertices.length;
			for (var i : uint = 0; i < len; ++i)
				_vertices[i] *= scale;
			invalidateBuffers(_vertexBufferContext);
		}
		
		override public function scaleUV(scaleU : Number = 1, scaleV : Number = 1):void
		{
			for (var i : uint = 0; i < _uvs.length;++i) {
				_uvs[i] /= _scaleU;
				_uvs[i] *= scaleU;
				i++;
				_uvs[i] /= _scaleV;
				_uvs[i] *= scaleV;
			}
			
			_scaleU = scaleU;
			_scaleV = scaleV;
			 
			invalidateBuffers(_uvBufferContext);
		}
		
		override public function dispose() : void
		{
			super.dispose();
			_vertices = null;
			_uvs = null;
			_secondaryUvs = null;
			_vertexNormals = null;
			_vertexTangents = null;
			_indices = null;
			_faceNormalsData = null;
			_faceWeights = null;
			_faceTangents = null;
			_customData = null;
		}
		
		public function get vertexData() : ByteArray
		{
			return _vertices;
		}
		
		public function updateCustomData(data : ByteArray) : void
		{
			invalidateBuffers(_customBufferContext);
		}

		/**
		 * Updates the vertex data of the SubGeometry.
		 * @param vertices The new vertex data to upload.
		 */
		public function updateVertexData(vertices : ByteArray, offset : int = 0, numverts : int = 0 ) : void
		{
			if (_autoDeriveVertexNormals) _vertexNormalsDirty = true;
			if (_autoDeriveVertexTangents) _vertexTangentsDirty = true;

			_faceNormalsDirty = true;

			_vertices = vertices;
			_verticesOffset = offset;
			if (numverts != _numVertices) disposeAllVertexBuffers();
			_numVertices = numverts || (vertices.length / 12);
            invalidateBuffers(_vertexBufferContext);

			invalidateBounds();
		}

		private function invalidateBounds() : void
		{
			if (_parentGeometry) _parentGeometry.invalidateBounds(this);
		}

		/**
		 * The raw texture coordinate data.
		 */
		public function get UVData() : ByteArray
		{
			return _uvs;
		}

		public function get secondaryUVData() : ByteArray
		{
			return _secondaryUvs;
		}

		/**
		 * Updates the uv coordinates of the SubGeometry.
		 * @param uvs The uv coordinates to upload.
		 */
		public function updateUVData(uvs : ByteArray, offset : int = 0) : void
		{
			// normals don't get dirty from this
			if (_autoDeriveVertexTangents) _vertexTangentsDirty = true;
			_faceTangentsDirty = true;
			_uvs = uvs;
			_uvsOffset = offset;
			invalidateBuffers(_uvBufferContext);
		}

		public function updateSecondaryUVData(uvs : ByteArray, offset : int = 0 ) : void
		{
			_secondaryUvs = uvs;
			_secondaryUvsOffset = offset;
			invalidateBuffers(_secondaryUvBufferContext);
		}

		/**
		 * The raw vertex normal data.
		 */
		public function get vertexNormalData() : ByteArray
		{
			if (_autoDeriveVertexNormals && _vertexNormalsDirty) updateVertexNormals();
			return _vertexNormals;
		}

		/**
		 * Updates the vertex normals of the SubGeometry. When updating the vertex normals like this,
		 * autoDeriveVertexNormals will be set to false and vertex normals will no longer be calculated automatically.
		 * @param vertexNormals The vertex normals to upload.
		 */
		public function updateVertexNormalData(vertexNormals : ByteArray, offset : int = 0) : void
		{
			_vertexNormalsDirty = false;
			_autoDeriveVertexNormals = (vertexNormals == null);
			_vertexNormals = vertexNormals;
			_vertexNormalsOffset = offset;
			invalidateBuffers(_vertexNormalBufferContext);
		}

		public function updateVertexColorData(vertexColors : ByteArray, offset : int = 0) : void
		{
			_vertexColorsDirty = false;
			_colors = vertexColors;
			_colorsOffset = offset;
			invalidateBuffers(_colorBufferContext);
		}

		/**
		 * The raw vertex tangent data.
		 *
		 * @private
		 */
		public function get vertexTangentData() : ByteArray
		{
			if (_autoDeriveVertexTangents && _vertexTangentsDirty) updateVertexTangents();
			return _vertexTangents;
		}

		/**
		 * Updates the vertex tangents of the SubGeometry. When updating the vertex tangents like this,
		 * autoDeriveVertexTangents will be set to false and vertex tangents will no longer be calculated automatically.
		 * @param vertexTangents The vertex tangents to upload.
		 */
		public function updateVertexTangentData(vertexTangents : ByteArray, offset : int = 0) : void
		{
			_vertexTangentsDirty = false;
			_autoDeriveVertexTangents = (vertexTangents == null);
			_vertexTangents = vertexTangents;
			_vertexTangentsOffset = offset;
			invalidateBuffers(_vertexTangentBufferContext);
		}

		/**
		 * The raw index data that define the faces.
		 *
		 * @private
		 */
		public function get indexData() : ByteArray
		{
			return _indices;
		}

		/**
		 * Updates the face indices of the SubGeometry.
		 * @param indices The face indices to upload.
		 */
		public function updateIndexData(indices : ByteArray, offset : int = 0, numIndices : int = 0 ) : void
		{
			_indices = indices;
			_indicesOffset = offset;
			_numIndices = numIndices || indices.length>>1;

			var numTriangles : int = (_numIndices/3);
			if (_numTriangles != numTriangles)
				disposeIndexBuffers(_indexBuffer);
			_numTriangles = numTriangles;
			invalidateBuffers(_indexBufferContext);
			_faceNormalsDirty = true;

			if (_autoDeriveVertexNormals) _vertexNormalsDirty = true;
			if (_autoDeriveVertexTangents) _vertexTangentsDirty = true;
		}
		
		
		
		
		
		override protected function updateVertexNormals() : void
		{
			
			if (_faceNormalsDirty)
				updateFaceNormals();

			var v1 : uint, v2 : uint, v3 : uint;
			var f1 : uint = 0, f2 : uint = 1, f3 : uint = 2;
			var lenV : uint = _vertices.length;

			// reset, yo
			if (_vertexNormals) while (v1 < lenV) _vertexNormals[v1++] = 0.0;
			else {
				_vertexNormals = new ByteArray();
				_vertexNormals.length = _vertices.length;
			}

			var i : uint, k : uint;
			var lenI : uint = _indices.length;
			var index : uint;
			var weight : uint;

			while (i < lenI) {
				weight = _useFaceWeights? _faceWeights[k++] : 1;
				index = _indices[i++]*3;
				_vertexNormals[index++] += _faceNormalsData[f1]*weight;
				_vertexNormals[index++] += _faceNormalsData[f2]*weight;
				_vertexNormals[index] += _faceNormalsData[f3]*weight;
				index = _indices[i++]*3;
				_vertexNormals[index++] += _faceNormalsData[f1]*weight;
				_vertexNormals[index++] += _faceNormalsData[f2]*weight;
				_vertexNormals[index] += _faceNormalsData[f3]*weight;
				index = _indices[i++]*3;
				_vertexNormals[index++] += _faceNormalsData[f1]*weight;
				_vertexNormals[index++] += _faceNormalsData[f2]*weight;
				_vertexNormals[index] += _faceNormalsData[f3]*weight;
				f1 += 3;
				f2 += 3;
				f3 += 3;
			}

			v1 = 0; v2 = 1; v3 = 2;
			while (v1 < lenV) {
				var vx : Number = _vertexNormals[v1];
				var vy : Number = _vertexNormals[v2];
				var vz : Number = _vertexNormals[v3];
				var d : Number = 1.0/Math.sqrt(vx*vx+vy*vy+vz*vz);
				_vertexNormals[v1] *= d;
				_vertexNormals[v2] *= d;
				_vertexNormals[v3] *= d;
				v1 += 3;
				v2 += 3;
				v3 += 3;
			}

			_vertexNormalsDirty = false;
			invalidateBuffers(_vertexNormalBufferContext);
		}
		
		
		override protected function updateDummyUVs() : void
		{
			var uvs : Vector.<Number>;
			var i : uint, idx : uint, uvIdx : uint;
			var len : uint = _vertices.length / 3 * 2;
			
			_uvs ||= new ByteArray();
			
			idx = 0;
			uvIdx = 0;
			while (idx < len) {
				if (uvIdx==0) {
					_uvs[idx++] = 0.0;
					_uvs[idx++] = 1.0;
				}
				else if (uvIdx==1) {
					_uvs[idx++] = 0.5;
					_uvs[idx++] = 0.0;
				}
				else if (uvIdx==2) {
					_uvs[idx++] = 1.0;
					_uvs[idx++] = 1.0;
				}
				
				uvIdx++;
				if (uvIdx==3)
					uvIdx = 0;
			}
			
			_uvsDirty = false;
			invalidateBuffers(_uvBufferContext);
		}

		/**
		 * Updates the vertex tangents based on the geometry.
		 */
		override protected function updateVertexTangents() : void
		{
			if (_vertexNormalsDirty) updateVertexNormals();

			if (_faceTangentsDirty)
				updateFaceTangents();

			var v1 : uint, v2 : uint, v3 : uint;
			var f1 : uint = 0, f2 : uint = 1, f3 : uint = 2;
			var lenV : uint = _vertices.length;

			if (_vertexTangents) while (v1 < lenV) _vertexTangents[v1++] = 0.0;
			else {
				_vertexTangents = new ByteArray();
				_vertexTangents.length = _vertices.length;
			}

			var i : uint, k : uint;
			var lenI : uint = _indices.length;
			var index : uint;
			var weight : uint;

			while (i < lenI) {
				weight = _useFaceWeights? _faceWeights[k++] : 1;
				index = _indices[i++]*3;
				_vertexTangents[index++] += _faceTangents[f1]*weight;
				_vertexTangents[index++] += _faceTangents[f2]*weight;
				_vertexTangents[index] += _faceTangents[f3]*weight;
				index = _indices[i++]*3;
				_vertexTangents[index++] += _faceTangents[f1]*weight;
				_vertexTangents[index++] += _faceTangents[f2]*weight;
				_vertexTangents[index] += _faceTangents[f3]*weight;
				index = _indices[i++]*3;
				_vertexTangents[index++] += _faceTangents[f1]*weight;
				_vertexTangents[index++] += _faceTangents[f2]*weight;
				_vertexTangents[index] += _faceTangents[f3]*weight;
				f1 += 3;
				f2 += 3;
				f3 += 3;
			}

			v1 = 0; v2 = 1; v3 = 2;
			while (v1 < lenV) {
				var vx : Number = _vertexTangents[v1];
				var vy : Number = _vertexTangents[v2];
				var vz : Number = _vertexTangents[v3];
				var d : Number = 1.0/Math.sqrt(vx*vx+vy*vy+vz*vz);
				_vertexTangents[v1] *= d;
				_vertexTangents[v2] *= d;
				_vertexTangents[v3] *= d;
				v1 += 3;
				v2 += 3;
				v3 += 3;
			}

			_vertexTangentsDirty = false;
			invalidateBuffers(_vertexTangentBufferContext);
		}

		/**
		 * Updates the normals for each face.
		 */
		override protected function updateFaceNormals() : void
		{
			var i : uint, j : uint, k : uint;
			var index : uint;
			var len : uint = _indices.length;
			var x1 : Number, x2 : Number, x3 : Number;
			var y1 : Number, y2 : Number, y3 : Number;
			var z1 : Number, z2 : Number, z3 : Number;
			var dx1 : Number, dy1 : Number, dz1 : Number;
			var dx2 : Number, dy2 : Number, dz2 : Number;
			var cx : Number, cy : Number, cz : Number;
			var d : Number;

			_faceNormalsData ||= new ByteArray();
			_faceNormalsData.length = len;
			if (_useFaceWeights) {
				_faceWeights ||= new ByteArray();
				_faceWeights.length = len/3
			}

			while (i < len) {
				index = _indices[i++]*3;
				x1 = _vertices[index++];
				y1 = _vertices[index++];
				z1 = _vertices[index];
				index = _indices[i++]*3;
				x2 = _vertices[index++];
				y2 = _vertices[index++];
				z2 = _vertices[index];
				index = _indices[i++]*3;
				x3 = _vertices[index++];
				y3 = _vertices[index++];
				z3 = _vertices[index];
				dx1 = x3-x1;
				dy1 = y3-y1;
				dz1 = z3-z1;
				dx2 = x2-x1;
				dy2 = y2-y1;
				dz2 = z2-z1;
				cx = dz1*dy2 - dy1*dz2;
				cy = dx1*dz2 - dz1*dx2;
				cz = dy1*dx2 - dx1*dy2;
				d = Math.sqrt(cx*cx+cy*cy+cz*cz);
				// length of cross product = 2*triangle area
				if (_useFaceWeights) {
					var w : Number = d*10000;
					if (w < 1) w = 1;
					_faceWeights[k++] = w;
				}
				d = 1/d;
				_faceNormalsData[j++] = cx*d;
				_faceNormalsData[j++] = cy*d;
				_faceNormalsData[j++] = cz*d;
			}

			_faceNormalsDirty = false;
			_faceTangentsDirty = true;
		}

		/**
		 * Updates the tangents for each face.
		 */
		override protected function updateFaceTangents() : void
		{
			var i : uint, j : uint;
			var index1 : uint, index2 : uint, index3 : uint;
			var len : uint = _indices.length;
			var ui : uint, vi : uint;
			var v0 : Number;
			var dv1 : Number, dv2 : Number;
			var denom : Number;
			var x0 : Number, y0 : Number, z0 : Number;
			var dx1 : Number, dy1 : Number, dz1 : Number;
			var dx2 : Number, dy2 : Number, dz2 : Number;
			var cx : Number, cy : Number, cz : Number;
			var invScale : Number = 1/_uvScaleV;

			_faceTangents ||= new ByteArray();
			_faceTangents.length = _indices.length;

			while (i < len) {
				index1 = _indices[i++];
				index2 = _indices[i++];
				index3 = _indices[i++];

				v0 = _uvs[uint((index1 << 1) + 1)];
				ui = index2 << 1;
				dv1 = (_uvs[uint((index2 << 1) + 1)] - v0)*invScale;
				ui = index3 << 1;
				dv2 = (_uvs[uint((index3 << 1) + 1)] - v0)*invScale;

				vi = index1*3;
				x0 = _vertices[vi];
				y0 = _vertices[uint(vi+1)];
				z0 = _vertices[uint(vi+2)];
				vi = index2*3;
				dx1 = _vertices[uint(vi)] - x0;
				dy1 = _vertices[uint(vi+1)] - y0;
				dz1 = _vertices[uint(vi+2)] - z0;
				vi = index3*3;
				dx2 = _vertices[uint(vi)] - x0;
				dy2 = _vertices[uint(vi+1)] - y0;
				dz2 = _vertices[uint(vi+2)] - z0;

				cx = dv2*dx1 - dv1*dx2;
				cy = dv2*dy1 - dv1*dy2;
				cz = dv2*dz1 - dv1*dz2;
				denom = 1/Math.sqrt(cx*cx + cy*cy + cz*cz);
				_faceTangents[j++] = denom*cx;
				_faceTangents[j++] = denom*cy;
				_faceTangents[j++] = denom*cz;
			}

			_faceTangentsDirty = false;
		}
		
		

		private function copyBytes(source : ByteArray) : ByteArray {
			var res : ByteArray = new ByteArray();
			res.writeBytes(source, 0, source.length);
			return res;
		}

		public function get customDataOffset() : int {
			return _customDataOffset;
		}

		public function get verticesOffset() : int {
			return _verticesOffset;
		}

		public function get colorsOffset() : int {
			return _colorsOffset;
		}

		public function get uvsOffset() : int {
			return _uvsOffset;
		}

		public function get secondaryUvsOffset() : int {
			return _secondaryUvsOffset;
		}

		public function get vertexNormalsOffset() : int {
			return _vertexNormalsOffset;
		}

		public function get vertexTangentsOffset() : int {
			return _vertexTangentsOffset;
		}

		public function get indicesOffset() : int {
			return _indicesOffset;
		}
	}
}
