package away3d.core.math
{
	import flash.geom.*;

	/**
	 * Matrix3DUtils provides additional Matrix3D math functions.
	 */
	public class Matrix3DUtils
	{
		/**
		 * A reference to a Vector to be used as a temporary raw data container, to prevent object creation.
		 */
		public static const RAW_DATA_CONTAINER : Vector.<Number> = new Vector.<Number>(16);
		
		// internal use only
		private static const _RAW : Vector.<Number> = new Vector.<Number>(16);

        /**
        * Fills the 3d matrix object with values representing the transformation made by the given quaternion.
        * 
        * @param	quarternion	The quarterion object to convert.
        */
        public static function quaternion2matrix(quarternion:Quaternion, m : Matrix3D = null):Matrix3D
        {
        	var x:Number = quarternion.x;
        	var y:Number = quarternion.y;
        	var z:Number = quarternion.z;
        	var w:Number = quarternion.w;
        	
            var xx:Number = x * x;
            var xy:Number = x * y;
            var xz:Number = x * z;
            var xw:Number = x * w;
    
            var yy:Number = y * y;
            var yz:Number = y * z;
            var yw:Number = y * w;
    
            var zz:Number = z * z;
            var zw:Number = z * w;

			var raw : Vector.<Number> = RAW_DATA_CONTAINER;
			raw[0] = 1 - 2 * (yy + zz); raw[1] = 2 * (xy + zw); raw[2] = 2 * (xz - yw); raw[4] = 2 * (xy - zw);
			raw[5] = 1 - 2 * (xx + zz); raw[6] = 2 * (yz + xw); raw[8] = 2 * (xz + yw); raw[9] = 2 * (yz - xw);
			raw[10] = 1 - 2 * (xx + yy);
			raw[3] = raw[7] = raw[11] = raw[12] = raw[13] = raw[14] = 0;
			raw[15] = 1;

            if (m) {
				m.copyRawDataFrom(raw);
				return m;
			}
			else	
				return new Matrix3D(raw);
		}

		public static function decompose( mtx : Matrix3D, pos : Vector3D, rot : Vector3D, scale : Vector3D ) : void {
			var raw : Vector.<Number> = _RAW;
			var sx : Number, sy : Number, sz : Number;
			
			mtx.copyRawDataTo( raw );
			
			var m11 :  Number = raw[uint(0)];
			var m21 :  Number = raw[uint(1)];
			var m31 :  Number = raw[uint(2)];
			var m12 :  Number = raw[uint(4)];
			var m22 :  Number = raw[uint(5)];
			var m32 :  Number = raw[uint(6)];
			var m13 :  Number = raw[uint(8)];
			var m23 :  Number = raw[uint(9)];
			var m33 :  Number = raw[uint(10)];

			pos.setTo( raw[uint(12)], raw[uint(13)], raw[uint(14)] );
			
			sx = Math.sqrt(m11*m11 + m21*m21 + m31*m31);
			sy = Math.sqrt(m12*m12 + m22*m22 + m32*m32);
			sz = Math.sqrt(m13*m13 + m23*m23 + m33*m33);
			
			scale.setTo(sx, sy, sz);
			
			sx = 1.0 / sx;
			sy = 1.0 / sy;
			sz = 1.0 / sz;
			
			m11 *= sx;
			m21 *= sx;
			m31 *= sx;
			m12 *= sy;
			m22 *= sy;
			m32 *= sy;
			m13 *= sz;
			m23 *= sz;
			m33 *= sz;
			
			
			rot.y = Math.asin(Math.min(Math.max(-m31, -1), 1));

			if ( Math.abs(m13) < 0.99999 ) {
				rot.x = Math.atan2(m32, m33);
				rot.z = Math.atan2(m21, m11);
			} else {
				rot.x = Math.atan2(m32, m22);
				rot.z = 0;
			}
			
			
		}

		public static function transformVector( mtx : Matrix3D, vin : Vector3D, vout : Vector3D ) : void {
			
			var raw : Vector.<Number> = _RAW;
			var sx : Number, sy : Number, sz : Number, sw : Number;
			
			var x : Number = vin.x;
			var y : Number = vin.y;
			var z : Number = vin.z;
			var w : Number = vin.w;
			
			mtx.copyRawDataTo( raw );
			
			sx = raw[uint(0)] * x + raw[uint(4)] * y + raw[uint(8)] * z  + raw[uint(12)] * w;
			sy = raw[uint(1)] * x + raw[uint(5)] * y + raw[uint(9)] * z  + raw[uint(13)] * w;
			sz = raw[uint(2)] * x + raw[uint(6)] * y + raw[uint(10)] * z + raw[uint(14)] * w;
			sw = raw[uint(3)] * x + raw[uint(7)] * y + raw[uint(11)] * z + raw[uint(15)] * w;
			
			vout.setTo( sx, sy, sz );
			vout.w = sw;
		}
		
		public static function deltaTransformVector( mtx : Matrix3D, vin : Vector3D, vout : Vector3D ) : void {
			
			var raw : Vector.<Number> = _RAW;
			var sx : Number, sy : Number, sz : Number;
			
			var x : Number = vin.x;
			var y : Number = vin.y;
			var z : Number = vin.z;
			
			mtx.copyRawDataTo( raw );
			
			sx = raw[uint(0)] * x + raw[uint(4)] * y + raw[uint(8)] * z;
			sy = raw[uint(1)] * x + raw[uint(5)] * y + raw[uint(9)] * z;
			sz = raw[uint(2)] * x + raw[uint(6)] * y + raw[uint(10)] * z;
			
			vout.setTo( sx, sy, sz );
		}


        
        /**
        * Returns a normalised <code>Vector3D</code> object representing the forward vector of the given matrix.
		* @param	m		The Matrix3D object to use to get the forward vector
		* @param	v 		[optional] A vector holder to prevent make new Vector3D instance if already exists. Default is null.
    	* @return			The forward vector
        */
        public static function getForward(m:Matrix3D, v:Vector3D = null):Vector3D
        {
			v ||= new Vector3D(0.0, 0.0, 0.0);
			m.copyColumnTo(2, v);
        	v.normalize();

        	return v;
        }
     	
     	/**
        * Returns a normalised <code>Vector3D</code> object representing the up vector of the given matrix.
        * @param	m		The Matrix3D object to use to get the up vector
		* @param	v 		[optional] A vector holder to prevent make new Vector3D instance if already exists. Default is null.
    	* @return			The up vector
        */
        public static function getUp(m:Matrix3D, v:Vector3D = null):Vector3D
        {
        	v ||= new Vector3D(0.0, 0.0, 0.0);
			m.copyColumnTo(1, v);
        	v.normalize();

        	return v;
        }
     	
     	/**
        * Returns a normalised <code>Vector3D</code> object representing the right vector of the given matrix.
		* @param	m		The Matrix3D object to use to get the right vector
		* @param	v 		[optional] A vector holder to prevent make new Vector3D instance if already exists. Default is null.
    	* @return			The right vector
        */
        public static function getRight(m:Matrix3D, v:Vector3D = null):Vector3D
        {
        	v ||= new Vector3D(0.0, 0.0, 0.0);
			m.copyColumnTo(0, v);
        	v.normalize();

        	return v;
        }
     	
     	/**
         * Returns a boolean value representing whether there is any significant difference between the two given 3d matrices.
         */
        public static function compare(m1:Matrix3D, m2:Matrix3D):Boolean
        {
        	var r1 : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
        	var r2 : Vector.<Number> = m2.rawData;
			m1.copyRawDataTo(r1);

			for (var i : uint = 0; i < 16; ++i)
				if (r1[i] != r2[i]) return false;
			
			return true;
        }

        public static function compareEpsilon(m1:Matrix3D, m2:Matrix3D, epsilon : Number = 0.0001 ):Boolean
        {
        	var r1 : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
        	var r2 : Vector.<Number> = m2.rawData;
			m1.copyRawDataTo(r1);

			for (var i : uint = 0; i < 16; ++i)
				if ( Math.abs( r1[i] - r2[i] )> epsilon ) return false;
			
			return true;
		}

		public static function orientationAngle(m1:Matrix3D, m2:Matrix3D) : Number {
			var v1 : Vector3D = new Vector3D(1.0, .0, .0);
			var v2 : Vector3D = new Vector3D(1.0, .0, .0);
			
			v1 = m1.deltaTransformVector(v1);
			v2 = m2.deltaTransformVector(v2);
			
			return Vector3D.angleBetween(v1, v2);
		}


		public static function lookAt(matrix : Matrix3D, pos : Vector3D, dir : Vector3D, up : Vector3D) : void
		{
			var dirN : Vector3D;
			var upN : Vector3D;
			var lftN : Vector3D;
			var raw : Vector.<Number> = RAW_DATA_CONTAINER;

			lftN = dir.crossProduct(up);
			lftN.normalize();

			upN = lftN.crossProduct(dir);
			upN.normalize();
			dirN = dir.clone();
			dirN.normalize();

			raw[0] = lftN.x;
			raw[1] = upN.x;
			raw[2] = -dirN.x;
			raw[3] = 0.0;

			raw[4] = lftN.y;
			raw[5] = upN.y;
			raw[6] = -dirN.y;
			raw[7] = 0.0;

			raw[8] = lftN.z;
			raw[9] = upN.z;
			raw[10] = -dirN.z;
			raw[11] = 0.0;

			raw[12] = -lftN.dotProduct(pos);
			raw[13] = -upN.dotProduct(pos);
			raw[14] = dirN.dotProduct(pos);
			raw[15] = 1.0;

			matrix.copyRawDataFrom(raw);
		}

//		public static function is2D(m : Matrix3D, scale : Number = 1.0 ) : Boolean {
//			var raw : Vector.<Number> = m.rawData;
//			var eps : Number = 0.00001;
//			
//			
//			if( Math.abs(raw[uint(1)]) > eps ) return false;
//			if( Math.abs(raw[uint(2)]) > eps ) return false;
//			if( Math.abs(raw[uint(4)]) > eps ) return false;
//			if( Math.abs(raw[uint(6)]) > eps ) return false;
//			if( Math.abs(raw[uint(8)]) > eps ) return false;
//			if( Math.abs(raw[uint(9)]) > eps ) return false;
//			if( Math.abs(raw[uint(0)] - scale ) > eps ) return false;
//			if( Math.abs(raw[uint(5)] - scale ) > eps ) return false;
//			if( Math.abs(raw[uint(10)] - scale ) > eps ) return false;
//			return true;
//		}
	}
}
