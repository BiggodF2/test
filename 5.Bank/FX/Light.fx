
//ƽ�й�
struct DirLight
{
	float4	ambient;	//������
	float4	diffuse;	//�������
	float4	specular;	//�߹�

	float3	dir;		//����
	float	unused;		//��4D������������
};

//���Դ
struct PointLight
{
	float4	ambient;	//������
	float4	diffuse;	//�������
	float4	specular;	//�߹�

	float3	pos;		//��Դλ��
	float	range;		//��Դ���䷶Χ

	float3	att;		//��ǿ˥��ϵ��
	float	unused;		//"4D����"������
};

//�۹��
struct SpotLight
{
	float4	ambient;	//������
	float4	diffuse;	//�������
	float4	specular;	//�߹�

	float3	dir;		//����
	float	range;		//���䷶Χ

	float3	pos;		//λ��
	float	spot;		//�۹�ǿ��ϵ��

	float3	att;		//���ϵ��
	float	theta;		//���ɢ�Ƕ�
};

//����
struct Material
{
	float4	ambient;
	float4	diffuse;
	float4	specular;	//specular�е�4��Ԫ�ش�����ʵı���⻬�̶�
};

void BankBRDF(  Material mat,
				DirLight L,
				float3	position,//����λ��
				float3	normal,
				float3	toEye,
				out 	float4 ambient,
				out		float4 diffuse,
				out		float4 specular)
{
	//��ʼ��  
    ambient  = float4(0.f,0.f,0.f,0.f);
	diffuse  = float4(0.f,0.f,0.f,0.f);
	specular = float4(0.f,0.f,0.f,0.f);
	float  g_shininess  = 20.0f ;
	ambient = mat.ambient * L.ambient;
	float ln = saturate(dot(L.dir,normal));
	// �����������ǿ
	diffuse = mat.diffuse*ln;
	
	bool back = (dot(L.dir,normal)) && (dot(normal,toEye)>0);
	
	// ��������������߹�Ϊ0 
	if (back)
	{
	// ���㶥�������� 
	float3 T  =  normalize( cross( normal, toEye ) ); 
	float LT  =  dot(L.dir, T );
	float VT  =  dot( toEye, T );
	float a  =  sqrt(  1 -  pow( LT,2.0f) )  *  sqrt(  1 -  pow( VT,  2.0f  ) )  -  LT  *  VT;
	specular.xyz  =  pow( a, g_shininess )*mat.specular*ln;
	specular.w = 1;	
	}
}

